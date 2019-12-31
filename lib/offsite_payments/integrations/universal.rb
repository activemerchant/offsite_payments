module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module Universal
      def self.notification(post, options = {})
        Notification.new(post, options)
      end

      def self.return(query_string, options = {})
        Return.new(query_string, options)
      end

      def self.sign(fields, key)
        OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA256.new, key, fields.sort.join)
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
          @forward_url = options[:forward_url]
          @key = options[:credential2]
          @currency = options[:currency]

          # x_credential3 should not be included in the request when using the universal offsite dev kit.
          options[:credential3] = nil if options[:credential3] == @forward_url

          super
          self.country = options[:country]
          self.account_name = options[:account_name]
          self.transaction_type = options[:transaction_type]
          add_field 'x_test', @test.to_s
        end

        def credential_based_url
          @forward_url
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
          fields_to_sign = @fields.select { |key, _| key.start_with?('x_') && key != 'x_signature' }
          Universal.sign(fields_to_sign, @key)
        end

        mapping :account,          'x_account_id'
        mapping :currency,         'x_currency'
        mapping :order,            'x_reference'
        mapping :country,          'x_shop_country'
        mapping :account_name,     'x_shop_name'
        mapping :transaction_type, 'x_transaction_type'
        mapping :description,      'x_description'
        mapping :invoice,          'x_invoice'
        mapping :credential3,      'x_credential3'
        mapping :credential4,      'x_credential4'

        mapping :customer, :first_name => 'x_customer_first_name',
                           :last_name  => 'x_customer_last_name',
                           :email      => 'x_customer_email',
                           :phone      => 'x_customer_phone'

        mapping :billing_address, :first_name => 'x_customer_billing_first_name',
                                  :last_name =>  'x_customer_billing_last_name',
                                  :city =>       'x_customer_billing_city',
                                  :company =>    'x_customer_billing_company',
                                  :address1 =>   'x_customer_billing_address1',
                                  :address2 =>   'x_customer_billing_address2',
                                  :state =>      'x_customer_billing_state',
                                  :zip =>        'x_customer_billing_zip',
                                  :country =>    'x_customer_billing_country',
                                  :phone =>      'x_customer_billing_phone'

        mapping :shipping_address, :first_name => 'x_customer_shipping_first_name',
                                   :last_name =>  'x_customer_shipping_last_name',
                                   :city =>       'x_customer_shipping_city',
                                   :company =>    'x_customer_shipping_company',
                                   :address1 =>   'x_customer_shipping_address1',
                                   :address2 =>   'x_customer_shipping_address2',
                                   :state =>      'x_customer_shipping_state',
                                   :zip =>        'x_customer_shipping_zip',
                                   :country =>    'x_customer_shipping_country',
                                   :phone =>      'x_customer_shipping_phone'

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
          signature && signature.casecmp(generate_signature) == 0
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
          Universal.sign(signature_params, @key)
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
