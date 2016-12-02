module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    # Documentation: http://robokassa.ru/Doc/En/Interface.aspx
    module Robokassa
      # Overwrite this if you want to change the Robokassa test url
      mattr_accessor :test_url
      self.test_url = 'http://test.robokassa.ru/Index.aspx'

      # Overwrite this if you want to change the Robokassa production url
      mattr_accessor :production_url
      self.production_url = 'https://merchant.roboxchange.com/Index.aspx'

      mattr_accessor :signature_parameter_name
      self.signature_parameter_name = 'SignatureValue'

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

      module Common
        def generate_signature_string
          custom_param_keys = params.keys.select {|key| key =~ /^shp/}.sort
          custom_params = custom_param_keys.map {|key| "#{key}=#{params[key]}"}
          [main_params, secret, custom_params.compact].flatten.join(':')
        end

        def generate_signature
          Digest::MD5.hexdigest(generate_signature_string)
        end
      end

      class Helper < OffsitePayments::Helper
        include Common

        def initialize(order, account, options = {})
          @md5secret = options.delete(:secret)
          super
        end

        def form_fields
          @fields.merge(OffsitePayments::Integrations::Robokassa.signature_parameter_name => generate_signature)
        end

        def main_params
          [:account, :amount, :order].map {|key| @fields[mappings[key]]}
        end

        def params
          @fields
        end

        def secret
          @md5secret
        end

        def method_missing(method_id, *args)
          method_id = method_id.to_s.gsub(/=$/, '')

          # support for robokassa custom parameters
          if method_id =~ /^shp/
            add_field method_id, args.last
          end

          super
        end

        mapping :account, 'MrchLogin'
        mapping :amount, 'OutSum'
        mapping :currency, 'IncCurrLabel'
        mapping :order, 'InvId'
        mapping :description, 'Desc'
        mapping :email, 'Email'
      end

      class Notification < OffsitePayments::Notification
        include Common

        def self.recognizes?(params)
          params.has_key?('InvId') && params.has_key?('OutSum')
        end

        def complete?
          true
        end

        def item_id
          params['InvId']
        end

        def security_key
          params[OffsitePayments::Integrations::Robokassa.signature_parameter_name].to_s.downcase
        end

        def gross
          params['OutSum']
        end

        def status
          'success'
        end

        def secret
          @options[:secret]
        end

        def main_params
          [gross, item_id]
        end

        def acknowledge(authcode = nil)
          security_key == generate_signature
        end

        def success_response(*args)
          "OK#{item_id}"
        end

        def currency
          'RUB'
        end
      end

      class Return < OffsitePayments::Return
        def item_id
          @params['InvId']
        end

        def amount
          @params['OutSum']
        end
      end
    end
  end
end
