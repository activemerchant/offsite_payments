module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    # Documentation:
    # http://wiki.webmoney.ru/projects/webmoney/wiki/Web_Merchant_Interface
    module Webmoney
      mattr_accessor :test_url
      self.test_url = "https://merchant.webmoney.ru/lmi/payment.asp"

      mattr_accessor :production_url
      self.production_url =  "https://merchant.webmoney.ru/lmi/payment.asp"

      mattr_accessor :signature_parameter_name
      self.signature_parameter_name = 'LMI_HASH'

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

      module Common
        def generate_signature_string
          "#{params['LMI_PAYEE_PURSE']}#{params['LMI_PAYMENT_AMOUNT']}#{params['LMI_PAYMENT_NO']}#{params['LMI_MODE']}#{params['LMI_SYS_INVS_NO']}#{params['LMI_SYS_TRANS_NO']}#{params['LMI_SYS_TRANS_DATE']}#{secret}#{params['LMI_PAYER_PURSE']}#{params['LMI_PAYER_WM']}"
        end

        def generate_signature
          Digest::MD5.hexdigest(generate_signature_string).upcase
        end
      end

      class Helper < OffsitePayments::Helper
        include Common

        def initialize(order, account, options = {})
          @webmoney_options = options.dup
          options.delete(:description)
          options.delete(:fail_url)
          options.delete(:success_url)
          options.delete(:result_url)
          super
          @webmoney_options.each do |key, value|
            add_field mappings[key], value
          end
        end

        def form_fields
          @fields
        end

        def params
          @fields
        end

        mapping :account, 'LMI_PAYEE_PURSE'
        mapping :amount, 'LMI_PAYMENT_AMOUNT'
        mapping :order, 'LMI_PAYMENT_NO'
        mapping :description, 'LMI_PAYMENT_DESC'
        mapping :fail_url, 'LMI_FAIL_URL'
        mapping :success_url, 'LMI_SUCCESS_URL'
        mapping :result_url, 'LMI_RESULT_URL'
        mapping :debug, 'LMI_SIM_MODE'
      end

      class Notification < OffsitePayments::Notification
        include Common

        def recognizes?
          (params.has_key?('LMI_PAYMENT_NO') && params.has_key?('LMI_PAYMENT_AMOUNT'))
        end

        def amount
          Money.from_amount(BigDecimal.new(gross), currency)
        end

        def key_present?
          params["LMI_HASH"].present?
        end

        def item_id
          params['LMI_PAYMENT_NO']
        end

        def gross
          params['LMI_PAYMENT_AMOUNT']
        end

        def security_key
          params["LMI_HASH"]
        end

        def secret
          @options[:secret]
        end

        def acknowledge(authcode = nil)
          (security_key == generate_signature)
        end

        def success_response(*args)
          {:nothing => true}
        end

        def currency
          'RUB'
        end
      end
    end
  end
end
