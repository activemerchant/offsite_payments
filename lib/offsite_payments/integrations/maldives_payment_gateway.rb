require 'offsite_payments/integrations/maldives_payment_gateway/helper'
require 'offsite_payments/integrations/maldives_payment_gateway/notification'

module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module MaldivesPaymentGateway

      mattr_accessor :test_service_url
      self.test_service_url = "https://testgateway.bankofmaldives.com.mv/SENTRY/PayementGateway/Application/RedirectLink
.aspx"

      mattr_accessor :production_service_url
      self.production_service_url = "https://bankofmaldives.com.mv/SENTRY/PayementGateway/Application/RedirectLink
.aspx"

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
          sha = Digest::SHA1.hexdigest(raw_signature_string)
          Base64.encode64(sha)
        end

        def raw_signature_string
          raise NotImplementedError.new("must implement it on your decent class")
        end

        def password
          Rails.configuration.offsite_payments['account']['password']
        end

        def merchant_id
          Rails.configuration.offsite_payments['account']['merchant_id']
        end

        def acquirer_id
          Rails.configuration.offsite_payments['account']['acquirer_id']
        end
      end

      class Helper < OffsitePayments::Helper
        include Common
        def initialize(order, account, options = {})
          super

          add_field('Version', '1.0.0')
          add_field('SignatureMethod', 'SHA1')
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
        mapping :order_id, 'OrderID',

        # This is the signature method used to calculate the signature
        mapping :signature_method, 'SignatureMethod'

        # This is the total amount of the purchase
        mapping :amount, 'PurchaseAmt'

        # This is a digital signature that will verify that the contents of
        # this Web Page will not be altered in transit. (MPG will verify this signature)
        mapping :signature, 'Signature'

        def form_fields
          @fields.merge(mappings[:signature], generate_signature)
        end

        private

        def raw_signature_string
          [password, merchant_id, acquirer_id, order_id, amount, currency].join
        end

        def merchant_id
          fields[mappings[:merchant_id]]
        end

        def acquirer_id
          fields[mappings[:acquirer_id]]
        end

        def order_id
          fields[mappings[:order_id]]
        end

        def amount
          fields[mappings[:amount]]
        end

        def currency
          fields[mappings[:currency]]
        end
      end

      class Notification < OffsitePayments::Notification
        include Common

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

        def acknowledge(order_id)
          @order_id = order_id
          generate_signature == signature
        end

        private

        def raw_signature_string
          [pasword, merchant_id, acquirer_id, @order_id].join
        end

        # Take the posted data and move the relevant data into a hash
        def parse(post)
          @raw = post.to_s
          for line in @raw.split('&')
            key, value = *line.scan( %r{^([A-Za-z0-9_.-]+)\=(.*)$} ).flatten
            params[key] = CGI.unescape(value.to_s) if key.present?
          end
        end
      end
    end
  end
end
