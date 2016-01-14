module OffsitePayments
  module Integrations
    module PoliPay
      def self.notification(post, options = {})
        Notification.new(post, options)
      end

      def self.return(query_string, options = {})
        Return.new(query_string, options)
      end

      def self.sign(fields, key)
        OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA256.new, key, fields.sort.join)
      end

      class Interface
        include ActiveUtils::PostsData # ssl_get/post

        def self.base_url
          "https://poliapi.apac.paywithpoli.com/api"
        end

        def initialize(login, password)
          @login = login
          @password = password
        end

        private

        def standard_headers
          authorization = Base64.encode64("#{@login}:#{@password}")
          {
            'Content-Type' => 'application/json',
            'Authorization' => "Basic #{authorization}"
          }
        end

        def parse_response(raw_response)
          JSON.parse(raw_response)
        end

        class RequestError < StandardError
          attr_reader :exception, :message, :error_message, :error_code

          def initialize(exception)
            @exception = exception

            @response      = JSON.parse(exception.response.body)
            @success       = @response['Success']
            @message       = @response['Message']
            @error_message = @response['ErrorMessage']
            @error_code    = @response['ErrorCode']
          end

          def success?
            !!@success
          end

          def errors
            fail NotImplementedError, "This method must be implemented on the subclass"
          end

          def error_code_text
            errors[@error_code.to_s]
          end
        end
      end

      class UrlInterface < Interface
        def self.url
          "#{base_url}/Transaction/Initiate"
        end

        def call(options)
          raw_response = ssl_post(self.class.url, options.to_json, standard_headers)
          result = parse_response(raw_response)
          result['NavigateURL']
        rescue ActiveUtils::ResponseError => e
          raise UrlRequestError, e
        end

        class UrlRequestError < RequestError
          ERRORS = {
            '14050' => "A transaction-specific error has occurred",
            '14053' => "The amount specified exceeds the individual transaction limit set by the merchant",
            '14054' => "The amount specified will cause the daily transaction limit to be exceeded",
            '14055' => "General failure to initiate a transaction",
            '14056' => "Error in merchant-defined data",
            '14057' => "One or more values specified have failed a validation check",
            '14058' => "The monetary amount specified is invalid",
            '14059' => "A URL provided for one or more fields was not formatted correctly",
            '14060' => "The currency code supplied is not supported by POLi or the specific merchant",
            '14061' => "The MerchantReference field contains invalid characters",
            '14062' => "One or more fields that are mandatory did not have values specified",
            '14099' => "An unexpected error has occurred within transaction functionality"
          }

          def errors
            ERRORS
          end
        end
      end

      class QueryInterface < Interface
        def self.url(token)
          "#{base_url}/Transaction/GetTransaction?token=#{CGI.escape(token)}"
        end

        def call(token)
          raise ArgumentError, "Token must be specified" if token.blank?
          raw_response = ssl_get(self.class.url(token), standard_headers)
          parse_response(raw_response)
        rescue ActiveUtils::ResponseError => e
          raise QueryRequestError, e
        end

        class QueryRequestError < RequestError
          ERRORS = {
            '14050' => "Transaction was initiated by another merchant or another transaction-based error",
            '14051' => "The transaction was not found",
            '14052' => "The token provided was incomplete, corrupted or doesn't exist"
          }

          def errors
            ERRORS
          end
        end
      end

      class FinancialInstitutionsInterface < Interface
        def self.url
          "#{base_url}/Entity/GetFinancialInstitutions"
        end

        def call
          raw_response = ssl_get(self.class.url, standard_headers)
          result = parse_response(raw_response)
          result.map { |attr| FinancialInstitution.new(attr) }
        end
      end

      class Helper < OffsitePayments::Helper
        attr_reader :token_parameters

        def initialize(order, account, options = {})
          @login    = account
          @password = options.fetch(:password)
          @options  = options.except(:password).merge(order: order)
          super(order, account, options.except(:homepage_url, :password))
        end

        def credential_based_url
          options = TransactionBuilder.new(@options, self).to_hash
          UrlInterface.new(@login, @password).call(options)
        end
      end

      class TransactionBuilder
        SUPPORTED_CURRENCIES = ['AUD', 'NZD']

        def initialize(options, helper)
          @reference        = options.fetch(:order)
          @timeout          = options[:timeout] # or defaults
          @success_url      = options.fetch(:success_url, options.fetch(:return_url))
          @failure_url      = options.fetch(:failure_url, options.fetch(:return_url))
          @notification_url = helper.notify_url
          @homepage_url     = options.fetch(:homepage_url)
          self.amount       = options.fetch(:amount)
          self.currency     = options.fetch(:currency)
        end

        def amount=(amount)
          @amount = '%.2f' % amount.to_f.round(2)
        end

        def currency=(currency)
          unless SUPPORTED_CURRENCIES.include?(currency)
            raise ArgumentError, "Unsupported currency"
          end
          @currency = currency
        end

        def current_time
          Time.current.utc.strftime("%Y-%m-%dT%H:%M:%S")
        end

        def to_hash
          {
            Amount:              @amount,
            CurrencyCode:        @currency,
            MerchantReference:   @reference,
            SuccessURL:          @success_url,
            FailureURL:          @failure_url,
            NotificationUrl:     @notification_url,
            MerchantHomepageURL: @homepage_url,
            Timeout:             @timeout,
            MerchantDateTime:    current_time
          }.reject { |_, v| v.blank? }
        end
      end

      # See
      # http://www.polipaymentdeveloper.com/gettransaction#gettransaction_response
      class Notification < OffsitePayments::Notification
        def initialize(params, options = {})
          token = params.fetch('token')
          @params = QueryInterface.new(options[:login], options[:password]).call(token)
        end

        def acknowledge
          true # always valid as we fetch direct from poli
        end

        def complete?
          @params['TransactionStatusCode'] == 'Completed'
        end

        def success?
          complete? && gross && gross > 0
        end

        def gross
          @params['AmountPaid']
        end

        def currency
          @params['CurrencyCode']
        end

        def order_id
          @params['MerchantReference']
        end

        def transaction_id
          @params['TransactionRefNo']
        end

        # There is only a message on failure
        # http://www.polipaymentdeveloper.com/initiate#initiatetransaction_response
        def message
          @params['ErrorMessage']
        end
      end

      class Return < OffsitePayments::Return
        def initialize(query_string, options={})
          @notification = Notification.new(query_string, options)
        end
      end

      # See
      # http://www.polipaymentdeveloper.com/ficode#getfinancialinstitutions_response
      class FinancialInstitution
        attr_reader :name, :code

        def initialize(attr)
           @name   = attr.fetch('Name')
           @code   = attr.fetch('Code')
           @online = attr.fetch('Online')
        end

        def online?
          !!@online
        end
      end
    end
  end
end
