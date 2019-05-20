module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module BitPay
      API_V1_URL = 'https://bitpay.com/api/invoice'
      API_V1_TOKEN_REGEX = /^[^0OIl]{44,}$/
      API_V2_URL = 'https://bitpay.com/invoices'

      mattr_accessor :service_url
      self.service_url = 'https://bitpay.com/invoice'

      def self.notification(post, options = {})
        Notification.new(post, options)
      end

      def self.helper(order, account, options = {})
        Helper.new(order, account, options)
      end

      def self.return(query_string, options = {})
        Return.new(query_string)
      end

      def self.v2_api_token?(api_token)
        API_V1_TOKEN_REGEX.match(api_token)
      end

      def self.invoicing_url(api_token)
        if v2_api_token?(api_token)
          API_V2_URL
        else
          API_V1_URL
        end
      end

      class Helper < OffsitePayments::Helper
        def initialize(order_id, account, options)
          super
          @account = account
          @options = options

          add_field('posData', {'orderId' => order_id}.to_json)
          add_field('fullNotifications', true)
          add_field('transactionSpeed', 'high')
          add_field('token', @options[:credential2])

          if API_V1_TOKEN_REGEX.match(@options[:credential2])
            self.invoicing_url = 'https://bitpay.com/invoices'
          end
          
        end
        
       
        mapping :amount, 'price'
        mapping :order, 'orderID'
        mapping :currency, 'currency'

        mapping :customer, :first_name => 'buyerName',
                           :email      => 'buyerEmail',
                           :phone      => 'buyerPhone'

        mapping :billing_address, :city     => 'buyerCity',
                                  :address1 => 'buyerAddress1',
                                  :address2 => 'buyerAddress2',
                                  :state    => 'buyerState',
                                  :zip      => 'buyerZip',
                                  :country  => 'buyerCountry'

        mapping :notify_url, 'notificationURL'
        mapping :return_url, 'redirectURL'
        mapping :id, 'id'

        def form_method
          "GET"
        end

        def form_fields
          invoice = create_invoice

          raise ActionViewHelperError, "Invalid response while retrieving BitPay Invoice ID. Please try again." unless invoice

          {"id" => invoice['id']}
        end

        private

        def create_invoice
          uri = URI.parse(BitPay.invoicing_url(@options[:credential2]))
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true

          request = Net::HTTP::Post.new(uri.request_uri)
          request.content_type = "application/json"
          request.body = @fields.to_json
          request.basic_auth @account, ''

          response = http.request(request)
          JSON.parse(response.body)
        end
      end

      class Notification < OffsitePayments::Notification
        def complete?
          status == "Completed"
        end

        def transaction_id
          params['id']
        end

        def item_id
          JSON.parse(params['posData'])['orderId']
        end

        def status
          case params['status']
          when 'complete'
            'Completed'
          when 'confirmed'
            'Pending'
          when 'invalid'
            'Failed'
          end
        end

        # When was this payment received by the client.
        def received_at
          params['invoiceTime'].to_i
        end

        def currency
          params['currency']
        end

        def gross
          params['price'].to_f
        end

        def acknowledge(authcode = nil)
          uri = URI.parse("#{OffsitePayments::Integrations::BitPay.invoicing_url(@options[:credential2])}/#{transaction_id}")

          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true

          request = Net::HTTP::Get.new(uri.path)
          request.basic_auth @options[:credential2], ''

          response = http.request(request)

          posted_json = JSON.parse(@raw).tap { |j| j.delete('currentTime') }
          parse(response.body)
          retrieved_json = JSON.parse(@raw).tap { |j| j.delete('currentTime') }

          posted_json == retrieved_json
        end

        private
        def parse(body)
          @raw = body
          @params = JSON.parse(@raw)
        end
      end

      class Return < OffsitePayments::Return
      end
    end
  end
end
