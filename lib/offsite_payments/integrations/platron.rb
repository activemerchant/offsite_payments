require 'builder'

module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    # Platron API: www.platron.ru/PlatronAPI.pdf‎
    module Platron
      mattr_accessor :service_url
      self.service_url = 'https://www.platron.ru/payment.php'

      def self.notification(raw_post)
        Notification.new(raw_post)
      end

      def self.generate_signature_string(params, path, secret)
        sorted_params = params.sort_by{|k,v| k.to_s}.collect{|k,v| v}
        [path, sorted_params, secret].flatten.compact.join(';')
      end

      def self.generate_signature(params, path, secret)
        Digest::MD5.hexdigest(generate_signature_string(params, path, secret))
      end

      class Helper < OffsitePayments::Helper
        def initialize(order, account, options = {})
          @secret_key = options.delete(:secret)
          @path = options.delete(:path)
          description = options.delete(:description)
          super
          self.add_field('pg_salt', rand(36**15).to_s(36))
          self.add_field('pg_description', description)
        end

        def form_fields
          @fields.merge('pg_sig' => Common.generate_signature(@fields, @path, @secret_key))
        end

        def params
          @fields
        end

        mapping :account, 'pg_merchant_id'
        mapping :amount, 'pg_amount'
        mapping :order, 'pg_order_id'
        mapping :description, 'pg_description'
        mapping :currency, 'pg_currency'
      end

      class Notification < OffsitePayments::Notification
        def initialize(*args)
          super
          @signature = params.delete('pg_sig')
        end

        def complete?
          params['pg_result']
        end

        def order_id
          params['pg_order_id']
        end

        def platron_payment_id
          params['pg_payment_id']
        end

        def currency
          params['pg_ps_currency']
        end

        def payment_system
          params['pg_payment_system']
        end

        def user_phone
          params['pg_user_phone']
        end

        def card_brand
          params['pg_card_brand']
        end

        def captured
          params['pg_captured']
        end

        def overpayment
          params['pg_overpayment']
        end

        def failure_code
          params['pg_failure_code']
        end

        def failure_description
          params['pg_failure_description']
        end

        def payment_date
          params['pg_payment_date']
        end

        def salt
          params['pg_salt']
        end

        def signature
          @signature
        end

        def net_amount
          params['pg_net_amount']
        end

        def ps_amount
          params['pg_ps_amount']
        end

        def ps_full_amount
          params['pg_ps_full_amount']
        end

        def amount
          Money.from_amount(BigDecimal.new(params['pg_amount']), currency)
        end

        def secret
          @options[:secret]
        end

        def path
          @options[:path]
        end

        def acknowledge(authcode = nil)
          signature == Platron.generate_signature(params, path, secret)
        end

        def success_response(path,secret)
          salt = rand(36**15).to_s(36)
          xml = ""
          doc = Builder::XmlMarkup.new(:target => xml)
          sign = Platron.generate_signature({:pg_status => 'ok', :pg_salt => salt}, path, secret)
          doc.response do
            doc.pg_status 'ok'
            doc.pg_salt salt
            doc.pg_sig sign
          end
          xml
        end
      end
    end
  end
end
