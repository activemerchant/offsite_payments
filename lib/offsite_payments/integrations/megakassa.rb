module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    # Documentation: https://megakassa.ru/panel/api/
    module Megakassa
      mattr_accessor :test_url
      self.test_url = 'https://megakassa.ru/merchant/'

      mattr_accessor :production_url
      self.production_url = 'https://megakassa.ru/merchant/'

      mattr_accessor :signature_parameter_name
      self.signature_parameter_name = 'signature'

      def self.service_url
        mode = OffsitePayments.mode
        case mode
          when :production
            self.production_url
          when :test
            self.test_url
          else
            raise StandardError, "Integration mode set to an invalid value: #{mode}"
        end
      end

      def self.helper(order, account, options = {})
        Helper.new(order, account, options)
      end

      def self.notification(query_string, options = {})
        Notification.new(query_string, options)
      end

      def self.return(query_string)
        Return.new(query_string)
      end

      class Helper < OffsitePayments::Helper
        def generate_signature_string
          "#{params['shop_id']}:#{params['amount']}:#{params['currency']}:#{params['description']}:#{params['order_id']}:#{params['method_id']}:#{params['client_email']}:#{params['debug']}:#{secret}"
        end

        def generate_signature
          Digest::MD5.hexdigest(secret + Digest::MD5.hexdigest(generate_signature_string))
        end

        def normalize_amount(amount)
          int, float = amount.to_i, amount.to_f
          int == float ? int : float
        end

        def initialize(order, account, options = {})
          @md5secret = options.delete(:secret)

          super

          add_field :debug,       test? ? '1' : ''
          add_field :amount,      normalize_amount(options[:amount])
          add_field :description, options[:description]
        end

        def form_fields
          @fields.merge(OffsitePayments::Integrations::Megakassa.signature_parameter_name => generate_signature)
        end

        def params
          @fields
        end

        def secret
          @md5secret
        end

        mapping :account,     'shop_id'
        mapping :amount,      'amount'
        mapping :currency,    'currency'
        mapping :description, 'description'
        mapping :order,       'order_id'
        mapping :language,    'language'
        mapping :method,      'method_id'
        mapping :debug,       'debug'

        mapping :customer, email: 'client_email',
                phone: 'client_phone'
      end

      class Notification < OffsitePayments::Notification
        def generate_signature_string
          "#{uid}:#{gross}:#{gross_shop}:#{gross_client}:#{currency}:#{order_id}:#{payment_method_id}:#{payment_method_title}:#{client_email}:#{secret}"
        end

        def generate_signature
          Digest::MD5.hexdigest(generate_signature_string)
        end

        def complete?
          true
        end

        def uid
          params['uid']
        end

        def gross
          params['amount']
        end

        def gross_shop
          params['amount_shop']
        end

        def gross_shop_cents
          (gross_shop.to_f * 100.0).round
        end

        def amount_shop
          Money.new(gross_shop_cents, currency)
        end

        def gross_client
          params['amount_client']
        end

        def gross_client_cents
          (gross_client.to_f * 100.0).round
        end

        def amount_client
          Money.new(gross_client_cents, currency)
        end

        def currency
          params['currency']
        end

        def order_id
          params['order_id']
        end

        def payment_method_id
          params['payment_method_id']
        end

        def payment_method_title
          params['payment_method_title']
        end

        def client_email
          params['client_email']
        end

        def security_key
          params[OffsitePayments::Integrations::Megakassa.signature_parameter_name].to_s
        end

        def status
          'success'
        end

        def secret
          @options[:secret]
        end

        def acknowledge(authcode = nil)
          security_key == generate_signature
        end

        def success_response(*args)
          'ok'
        end
      end

      class Return < OffsitePayments::Return
        def order_id
          @params['order_id']
        end

        def amount
          @params['amount']
        end
      end
    end
  end
end
