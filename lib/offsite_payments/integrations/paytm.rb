module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module Paytm
    
      def self.notification(post, options = {})
        Notification.new(post, options)
      end

      def self.return(query_string, options = {})
        Return.new(query_string, options)
      end

      def self.sign(fields, key)
        Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::SHA256.new, key, fields.sort.join)).delete("\n")
      end

      class Helper < OffsitePayments::Helper
        CURRENCY_SPECIAL_MINOR_UNITS = {
          'BIF' => 0,
          'BYR' => 0,
          'CLF' => 0,
          'CLP' => 0,
          'CVE' => 0,
          'DJF' => 0,
          'GNF' => 0,
          'HUF' => 0,
          'ISK' => 0,
          'JPY' => 0,
          'KMF' => 0,
          'KRW' => 0,
          'PYG' => 0,
          'RWF' => 0,
          'UGX' => 0,
          'UYI' => 0,
          'VND' => 0,
          'VUV' => 0,
          'XAF' => 0,
          'XOF' => 0,
          'XPF' => 0,
          'BHD' => 3,
          'IQD' => 3,
          'JOD' => 3,
          'KWD' => 3,
          'LYD' => 3,
          'OMR' => 3,
          'TND' => 3,
          'COU' => 4
        }

        def initialize(order, account, options = {})
          mid_param = { MID: account }.to_query
          @forward_url_stag = "https://pguat.paytm.com/oltp-web/genericPT?#{mid_param}"
          @forward_url_prod = "https://secure.paytm.in/oltp-web/genericPT?#{mid_param}"
          @key = options[:credential2]
          @currency = options[:currency]

          super
          add_field 'x_test', @test.to_s
        end

        def credential_based_url
          @test ?  @forward_url_stag : @forward_url_prod
        end

        def form_fields
          sign_fields
        end

        def amount=(amount)
          add_field 'x_amount', format_amount(amount, @currency)
        end

        def sign_fields
          @fields.merge!('x_signature' => generate_signature)
        end

        def generate_signature
          Paytm.sign(@fields, @key)
        end

        mapping :account,          'x_account_id'
        mapping :currency,         'x_currency'
        mapping :order,            'x_reference'
        mapping :description,      'x_description'
        mapping :invoice,          'x_invoice'
        mapping :credential3,      'x_credential3'
        mapping :credential4,      'x_credential4'

        mapping :customer, :email      => 'x_customer_email',
                           :phone      => 'x_customer_phone'

        mapping        :notify_url, 'x_url_callback'
        mapping        :return_url, 'x_url_complete'
        mapping :cancel_return_url, 'x_url_cancel'

        private

        def format_amount(amount, currency)
          units = CURRENCY_SPECIAL_MINOR_UNITS[currency] || 2
          sprintf("%.#{units}f", amount)
        end
      end

      class Notification < OffsitePayments::Notification
        def initialize(post, options = {})
          super
          @key = options[:credential2]
        end

        def acknowledge(authcode = nil)
          signature = @params['x_signature']
          signature == generate_signature ? true : false
        end

        def item_id
          @params['x_reference']
        end

        def currency
          @params['x_currency']
        end

        def gross
          @params['x_amount']
        end

        def transaction_id
          @params['x_gateway_reference']
        end

        def status
          result = @params['x_result']
          result && result.capitalize
        end

        def message
          @params['x_message']
        end

        def test?
          @params['x_test'] == 'true'
        end

        private

        def generate_signature
          signature_params = @params.select { |k| k.start_with? 'x_' }.reject { |k| k == 'x_signature' }
          Paytm.sign(signature_params, @key)
        end
      end

      class Return < OffsitePayments::Return
        def initialize(query_string, options = {})
          super
          @notification = Notification.new(query_string, options)
        end

        def success?
          @notification.acknowledge
        end

        def message
          @notification.message
        end
      end
    end
  end
end