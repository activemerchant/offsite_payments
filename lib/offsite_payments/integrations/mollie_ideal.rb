module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module MollieIdeal
      include Mollie

      mattr_accessor :live_issuers
      self.live_issuers = [
        ["ABN AMRO", "ideal_ABNANL2A"],
        ["ASN Bank", "ideal_ASNBNL21"],
        ["Bunq", "ideal_BUNQNL2A"],
        ["ING", "ideal_INGBNL2A"],
        ["Knab", "ideal_KNABNL2H"],
        ["Rabobank", "ideal_RABONL2U"],
        ["RegioBank", "ideal_RBRBNL21"],
        ["SNS Bank", "ideal_SNSBNL2A"],
        ["Triodos Bank", "ideal_TRIONL2U"],
        ["van Lanschot", "ideal_FVLBNL22"]
      ]

      mattr_accessor :test_issuers
      self.test_issuers = [
        ["TBM Bank", "ideal_TESTNL99"]
      ]

      def self.redirect_param_label
        "Select your bank"
      end

      def self.redirect_param_options(options = {})
        return test_issuers if options[:credential1].blank?
        options[:credential1].start_with?('live_') ? live_issuers : test_issuers
      end

      def self.retrieve_issuers(token)
        response = API.new(token).get_request("issuers")
        response['data']
          .select { |issuer| issuer['method'] == 'ideal' }
          .map { |issuer| [issuer['name'], issuer['id']] }
      end

      RedirectError = Class.new(ActiveUtils::ActiveUtilsError)

      MOLLIE_API_V1_URI = 'https://api.mollie.nl/v1/'.freeze

      def self.notification(post, options = {})
        Notification.new(post, options)
      end

      def self.return(post, options = {})
        Return.new(post, options)
      end

      def self.live?
        OffsitePayments.mode == :production
      end

      def self.create_payment(token, params)
        API.new(token).post_request('payments', params)
      end

      def self.check_payment_status(token, payment_id)
        API.new(token).get_request("payments/#{payment_id}")
      end

      def self.requires_redirect_param?
        true
      end

      class Helper < OffsitePayments::Helper
        attr_reader :transaction_id, :redirect_parameters, :token

        def initialize(order, account, options = {})
          @token = account
          @redirect_parameters = {
            :amount => options[:amount],
            :description => options[:description],
            :issuer => options[:redirect_param],
            :redirectUrl => options[:return_url],
            :method => 'ideal',
            :metadata => { :order => order }
          }

          @redirect_parameters[:webhookUrl] = options[:notify_url] if options[:notify_url]

          super

          raise ArgumentError, "The redirect_param option needs to be set to the bank_id the customer selected." if options[:redirect_param].blank?
          raise ArgumentError, "The return_url option needs to be set." if options[:return_url].blank?
          raise ArgumentError, "The description option needs to be set." if options[:description].blank?
        end

        def credential_based_url
          response = request_redirect
          @transaction_id = response['id']

          uri = URI.parse(response['links']['paymentUrl'])
          set_form_fields_for_redirect(uri)
          uri.query = ''
          uri.to_s.sub(/\?\z/, '')
        end

        def form_method
          "GET"
        end

        def set_form_fields_for_redirect(uri)
          CGI.parse(uri.query).each do |key, value|
            if value.is_a?(Array) && value.length == 1
              add_field(key, value.first)
            else
              add_field(key, value)
            end
          end
        end

        def request_redirect
          MollieIdeal.create_payment(token, redirect_parameters)
        rescue ActiveUtils::ResponseError => e
          case e.response.code
          when '401', '403', '422'
            error = JSON.parse(e.response.body)['error']['message']
            raise ActionViewHelperError, error
          when '503'
            raise ActionViewHelperError, 'Service temporarily unavailable. Please try again.'
          else
            raise
          end
        end
      end

      class Notification < OffsitePayments::Notification
        def initialize(post_arguments, options = {})
          super

          raise ArgumentError, "The transaction_id needs to be included in the query string." if transaction_id.nil?
          raise ArgumentError, "The credential1 option needs to be set to the Mollie API key." if api_key.blank?
        end

        def complete?
          true
        end

        def item_id
          params['metadata']['order']
        end

        def transaction_id
          params['id']
        end

        def api_key
          @options[:credential1]
        end

        def currency
          "EUR"
        end

        # the money amount we received in X.2 decimal.
        def gross
          @params['amount']
        end

        def gross_cents
          (BigDecimal.new(@params['amount'], 2) * 100).to_i
        end

        def status
          case @params['status']
            when 'open';                 'Pending'
            when 'paidout', 'paid';      'Completed'
            else                         'Failed'
          end
        end

        def test?
          @params['mode'] == 'test'
        end

        def acknowledge(authcode = nil)
          @params = check_payment_status(transaction_id)
          true
        end

        def check_payment_status(transaction_id)
          MollieIdeal.check_payment_status(@options[:credential1], transaction_id)
        end
      end

      class Return < OffsitePayments::Return
      end
    end
  end
end
