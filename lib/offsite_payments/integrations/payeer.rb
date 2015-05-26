module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module Payeer
      mattr_accessor :service_url
      self.service_url = 'https://payeer.com/merchant/'

      def self.helper(order, account, options = {})
        Helper.new(order, account, options)
      end

      def self.notification(query_string, options = {})
        Notification.new(query_string, options)
      end

      module Common
        def generate_signature_string
          [main_params, secret].flatten.join(':')
        end

        def generate_signature
          Digest::SHA256.hexdigest(generate_signature_string).upcase
        end
      end

      class Helper < OffsitePayments::Helper
        include Common

        def initialize(order, account, options = {})
          @secret_key = options.delete(:secret)
          options[:amount] = options[:amount].nil? ? '0.00' : sprintf('%.2f' , options[:amount])
          options[:currency] ||= 'USD'
          options[:description] ||= ''
          description = Base64.encode64(options.delete(:description)).strip!
          super
          self.add_field('m_desc', description)
        end

        def form_fields
          @fields.merge('m_sign' => generate_signature)
        end

        def main_params
          [:account, :order, :amount, :currency, :description].map {|key| @fields[mappings[key]]}
        end

        def params
          @fields
        end

        def secret
          @secret_key
        end

        mapping :account, 'm_shop'
        mapping :order, 'm_orderid'
        mapping :amount, 'm_amount'
        mapping :currency, 'm_curr'
        mapping :description, 'm_desc'
      end

      class Notification < OffsitePayments::Notification
        include Common

        def initialize(*args)
          super
          @signature = params.delete('m_sign')
        end

        def self.recognizes?(params)
          params.has_key?('m_orderid') && params.has_key?('m_amount')
        end

        def complete?
          params['m_status'] == 'success'
        end

        %w(
          m_operation_id 
          m_operation_ps 
          m_operation_date
          m_operation_pay_date
          m_shop
          m_orderid
          m_amount
          m_status
        ).each do |param_name|
          define_method(param_name.underscore){ params[param_name] }
        end

        alias_method :item_id, :m_orderid
        alias_method :gross, :m_amount
        alias_method :status, :m_status

        def security_key
          @signature
        end

        def secret
          @options[:secret]
        end

        def main_params
          permited_params.values
        end

        def permited_params
          permited_keys = ["m_operation_id", "m_operation_ps", "m_operation_date", "m_operation_pay_date", "m_shop", "m_orderid", "m_amount", "m_curr", "m_desc", "m_status"]
          params.delete_if{ |key,value| !permited_keys.include? key }
        end

        def acknowledge(authcode = nil)
          security_key == generate_signature
        end

        def test_string
          generate_signature_string
        end

        def success_response(*args)
          "#{item_id}|success"
        end
      end
    end
  end
end