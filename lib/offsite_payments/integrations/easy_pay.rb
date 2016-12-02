module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    # Documentation: https://ssl.easypay.by/light/
    module EasyPay
      mattr_accessor :signature_parameter_name
      self.signature_parameter_name = 'EP_Hash'

      mattr_accessor :notify_signature_parameter_name
      self.notify_signature_parameter_name = 'notify_signature'

      mattr_accessor :service_url
      self.service_url = 'https://ssl.easypay.by/weborder/'

      def self.helper(order, account, options = {})
        Helper.new(order, account, options)
      end

      def self.notification(query_string, options = {})
        Notification.new(query_string, options)
      end

      module Common
        def generate_signature(type)
          string = case type
          when :request
            request_signature_string
          when :notify
            notify_signature_string
          end

          Digest::MD5.hexdigest(string)
        end

        def request_signature_string
          [
            @fields[mappings[:account]],
            @secret,
            @fields[mappings[:order]],
            @fields[mappings[:amount]]
          ].join
        end

        def notify_signature_string
          [
            params['order_mer_code'],
            params['sum'],
            params['mer_no'],
            params['card'],
            params['purch_date'],
            secret
          ].join
        end
      end

      class Helper < OffsitePayments::Helper
        include Common

        def initialize(order, account, options = {})
          super
          @secret = options[:credential2]
        end

        def form_fields
          @fields.merge(OffsitePayments::Integrations::EasyPay.signature_parameter_name => generate_signature(:request))
        end

        def params
          @fields
        end

        mapping :account, 'EP_MerNo'
        mapping :amount, 'EP_Sum'
        mapping :order, 'EP_OrderNo'
        mapping :comment, 'EP_Comment'
        mapping :order_info, 'EP_OrderInfo'
        mapping :expires, 'EP_Expires'
        mapping :success_url, 'EP_Success_URL'
        mapping :cancel_url, 'EP_Cancel_URL'
        mapping :debug, 'EP_Debug'
        mapping :url_type, 'EP_URL_Type'
        mapping :encoding, 'EP_Encoding'
      end

      class Notification < OffsitePayments::Notification
        include Common

        def initialize(data, options)
          if options[:credential2].nil?
            raise ArgumentError, "You need to provide the md5 secret as the option :credential2 to verify that the notification originated from EasyPay"
          end

          super
        end

        def self.recognizes?(params)
          params.has_key?('order_mer_code') && params.has_key?('sum')
        end

        def complete?
          true
        end

        def amount
          Money.from_amount(BigDecimal.new(gross), currency)
        end

        def item_id
          params['order_mer_code']
        end

        def security_key
          params[OffsitePayments::Integrations::EasyPay.notify_signature_parameter_name]
        end

        def gross
          params['sum']
        end

        def status
          'Completed'
        end

        def secret
          @options[:credential2]
        end

        def acknowledge(authcode = nil)
          security_key == generate_signature(:notify)
        end

        def success_response(*args)
          { :nothing => true }
        end

        def currency
          'BYR'
        end
      end
    end
  end
end
