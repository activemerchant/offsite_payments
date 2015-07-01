require 'money'

module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module MaldivesPaymentGateway

      mattr_accessor :test_service_url
      self.test_service_url = "https://testgateway.bankofmaldives.com.mv/SENTRY/PayementGateway/Application/RedirectLink.aspx"

      mattr_accessor :production_service_url
      self.production_service_url = 'https://egateway.bankofmaldives.com.mv/SENTRY/PaymentGateway/Application/RedirectLink.aspx'

      mattr_accessor :service_url
      def self.service_url
        mode = OffsitePayments.mode
        case mode
        when :production
          self.production_service_url
        when :test
          self.test_service_url
        end
      end

      def self.notification(post)
        Notification.new(post)
      end

      module Common
        protected

        def generate_signature
          Digest::SHA1.base64digest(raw_signature_string).strip
        end

        def raw_signature_string
          raise NotImplementedError.new("must implement it in your class")
        end

        def convert_amount(amount, exponent)
          amount = amount.to_f
          coefficient = coefficient(exponent)
          amount = (amount * coefficient).to_i
          amount.to_s.rjust(12, '0')
        end

        def coefficient(exponent)
          zeros = exponent.to_i
          10 ** zeros
        end

        def get_currency_iso_numeric(currency_code)
          money = Money.new(100, currency_code)
          if money
            money.currency.iso_numeric
          else
            currency_code
          end
        end
      end

      class Helper < OffsitePayments::Helper
        include Common
        def initialize(order, account, options = {})
          options.assert_valid_keys(:currency, :amount, :merchant_id,
                                    :acquirer_id, :response_url, :currency_exponent, :password, :test)
          @fields             = {}
          @raw_html_fields    = []
          @test               = options.delete(:test)

          options.each_pair { |key, val| self.send("#{key}=", val) }

          @password = account[:password]
          add_field(mappings[:merchant_id], account[:merchant_id])
          add_field(mappings[:acquirer_id], account[:acquirer_id])
          add_field(mappings[:version], '1.0.0')
          add_field(mappings[:signature_method], 'SHA1')
          add_field(mappings[:order_id], order)
          add_field(mappings[:currency], get_currency_iso_numeric(currency))
          add_field(mappings[:amount], convert_amount(amount, exponent).to_s)
          add_field(mappings[:signature], generate_signature)
        end
        # This is the version of the MPG and currently it has to be set to 1.0.0.
        mapping :version, 'Version'

        # This is your Merchant ID as set in MPG (will be provided by your MPG Provider).
        mapping :merchant_id, 'MerId'

        # This is your Acquierer ID (will be provided by your MPG Provider)
        mapping :acquirer_id, 'AcqID'

        # This is the URL of a Web Page on your server where the response will be sent.
        mapping :response_url, 'MerRespURL'

        # This is the standard ISO code of the currency used for the transaction.
        mapping :currency, 'PurchaseCurrency'

        # This is the number of decimal places used in the amount (usually 2).
        mapping :currency_exponent, 'PurchaseCurrencyExponent'

        # This is your own Order ID that will be used to match your Orders with
        # MPG transactions. It is recommended that this Order ID is always unique.
        mapping :order_id, 'OrderID'

        # This is the signature method used to calculate the signature
        mapping :signature_method, 'SignatureMethod'

        # This is the total amount of the purchase
        mapping :amount, 'PurchaseAmt'

        # This is a digital signature that will verify that the contents of
        # this Web Page will not be altered in transit. (MPG will verify this signature)
        mapping :signature, 'Signature'

        private

        def currency
          fields[mappings[:currency]]
        end

        def exponent
          fields[mappings[:currency_exponent]]
        end

        def password
          @password
        end

        def raw_signature_string
          [password, merchant_id, acquirer_id, order_id, amount, currency].join
        end

        def order_id
          fields[mappings[:order_id]]
        end

        def merchant_id
          fields[mappings[:merchant_id]]
        end

        def acquirer_id
          fields[mappings[:acquirer_id]]
        end

        def amount
          fields[mappings[:amount]]
        end
      end

      class Notification < OffsitePayments::Notification
        include Common

        attr_reader :order_id, :merchant_id, :acquirer_id, :password

        def response_code
          params['ResponseCode']
        end

        def reason_code
          params['ReasonCode']
        end

        def reason_description
          params['ReasonCodeDesc']
        end

        def reference_no
          params['ReferenceNo']
        end

        def signature
          params['Signature']
        end

        def transaction_approved?
          response_code == '1'
        end

        def acknowledge(merchant_id, acquirer_id, order_id, password)
          @order_id, @merchant_id, @acquirer_id, @password = order_id, merchant_id, acquirer_id, password

          generate_signature == signature
        end

        private

        def raw_signature_string
          [password, merchant_id, acquirer_id, order_id, response_code, reason_code].join
        end

        # Take the posted data and move the relevant data into a hash
        def parse(post)
          @raw = post.to_s
          for line in @raw.split("\n")
            key, value = *line.scan( %r{^([A-Za-z0-9_.-]+)\:(.*)$} ).flatten
            params[key.strip] = CGI.unescape(value.to_s.strip) if key.present?
          end
        end
      end
    end
  end
end
