module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module Realex
      mattr_accessor :production_url
      mattr_accessor :test_url
      self.production_url = 'https://hpp.realexpayments.com/pay'
      self.test_url       = 'https://hpp.sandbox.realexpayments.com/pay'

      def self.helper(order, account, options={})
        Helper.new(order, account, options)
      end

      def self.notification(query_string, options={})
        Notification.new(query_string, options)
      end

      def self.return(query_string, options={})
        Return.new(query_string, options)
      end

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

      module Common

        def create_signature(fields, secret)
          data = fields.join('.')
          digest = Digest::SHA1.hexdigest(data)
          signed = "#{digest}.#{secret}"
          Digest::SHA1.hexdigest(signed)
        end

      end

      class Helper < OffsitePayments::Helper
        include Common
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
          @timestamp   = Time.now.to_i.to_s
          @currency    = options[:currency]
          @merchant_id = options[:credential2]
          @sub_account = options[:credential3]
          @secret      = options[:credential4]
          super
          # Credentials
          add_field 'MERCHANT_ID', @merchant_id
          add_field 'ACCOUNT', @sub_account
          # Defaults
          add_field 'AUTO_SETTLE_FLAG', '1'
          add_field 'RETURN_TSS', '1'
          add_field 'TIMESTAMP', @timestamp
          add_field 'COMMENT1', 'Shopify'
        end

        def form_fields
          sign_fields
        end

        def amount=(amount)
          add_field 'AMOUNT', format_amount(amount, @currency)
        end

        def sign_fields
          @fields.merge!('SHA1HASH' => generate_signature)
        end

        def generate_signature
          fields_to_sign = []
          ['TIMESTAMP', 'MERCHANT_ID', 'ORDER_ID', 'AMOUNT', 'CURRENCY'].each do |field|
            fields_to_sign << @fields[field]
          end

          create_signature(fields_to_sign, @secret)
        end

        # Realex Required Fields
        mapping :currency,         'CURRENCY'
        mapping :order,            'ORDER_ID'
        mapping :amount,           'AMOUNT'
        mapping :return_url,       'MERCHANT_RESPONSE_URL'

        # Realex Optional fields
        mapping :customer,         :email => 'CUST_NUM'

        mapping :shipping_address, :zip =>        'SHIPPING_CODE',
                                   :country =>    'SHIPPING_CO'
        mapping :billing_address,  :zip =>        'BILLING_CODE',
                                   :country =>    'BILLING_CO'


        private

        # Realex accepts currency amounts as an integer in the lowest value
        # e.g. 
        #     format_amount(110.56, 'GBP')
        #     => 11056
        def format_amount(amount, currency)
          units = CURRENCY_SPECIAL_MINOR_UNITS[currency] || 2
          multiple = 10**units
          return (amount.to_f * multiple.to_f).to_i
        end
      end

      class Notification < OffsitePayments::Notification
        include Common
        def initialize(post, options={})
          super
          @secret = options[:credential4]
        end

        # Required Notification methods to define
        def status
          if result == '00'
            'Completed'
          else
            'Invalid'
          end
        end

        # TODO: Realex does not send back the currency param
        def gross
          params['AMOUNT'].to_f/100.0
        end

        def complete?
          verified? && status == 'Completed'
        end

        # Fields for Realex signature verification
        def timestamp
          params['TIMESTAMP']
        end

        def merchant_id
          params['MERCHANT_ID']
        end

        def order_id
          params['ORDER_ID']
        end

        def result
          params['RESULT']
        end

        def message
          params['MESSAGE']
        end

        def pasref
          params['PASREF']
        end

        def authcode
          params['AUTHCODE']
        end

        def signature
          params['SHA1HASH']
        end

        def calculated_signature
          fields = [timestamp, merchant_id, order_id, result, message, pasref, authcode]
          create_signature(fields, @secret)
        end

        def verified?
          signature == calculated_signature
        end

      end

      class Return < OffsitePayments::Return
        def initialize(data, options)
          super
          @notification = Notification.new(data, options)
        end

        def success?
          notification.complete?
        end

        # TODO: realex does not provide a separate cancelled endpoint
        def cancelled?
          false
        end

        def message
          notification.message
        end
      end

    end
  end
end
