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

      class Helper < OffsitePayments::Helper
        # Replace with the real mapping
        mapping :account, ''
        mapping :amount, ''

        mapping :order, ''

        mapping :customer, :first_name => '',
                           :last_name  => '',
                           :email      => '',
                           :phone      => ''

        mapping :billing_address, :city     => '',
                                  :address1 => '',
                                  :address2 => '',
                                  :state    => '',
                                  :zip      => '',
                                  :country  => ''

        mapping :notify_url, ''
        mapping :return_url, ''
        mapping :cancel_return_url, ''
        mapping :description, ''
        mapping :tax, ''
        mapping :shipping, ''

        # This is the version of the MPG and currently it has to be set to 1.0.0.
        mapping :version, 'Version'

        # This is your Merchant ID as set in MPG (will be provided by your MPG Provider).
        mapping :merchant_id, 'MerId'

        # This is your Acquierer ID (will be provided by your MPG Provider)
        mapping :acquierer_id, 'AcqID'

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
        mapping :purchase_amount, 'PurchaseAmt'

        # This is a digital signature that will verify that the contents of
        # this Web Page will not be altered in transit. (MPG will verify this signature)
        mapping :signature, 'Signature'
      end

      class Notification < OffsitePayments::Notification
        def complete?
          params['']
        end

        def item_id
          params['']
        end

        def transaction_id
          params['']
        end

        # When was this payment received by the client.
        def received_at
          params['']
        end

        def payer_email
          params['']
        end

        def receiver_email
          params['']
        end

        def security_key
          params['']
        end

        # the money amount we received in X.2 decimal.
        def gross
          params['']
        end

        # Was this a test transaction?
        def test?
          params[''] == 'test'
        end

        def status
          params['']
        end

        # Acknowledge the transaction to MaldivesPaymentGateway. This method has to be called after a new
        # apc arrives. MaldivesPaymentGateway will verify that all the information we received are correct and will return a
        # ok or a fail.
        #
        # Example:
        #
        #   def ipn
        #     notify = MaldivesPaymentGatewayNotification.new(request.raw_post)
        #
        #     if notify.acknowledge
        #       ... process order ... if notify.complete?
        #     else
        #       ... log possible hacking attempt ...
        #     end
        def acknowledge(authcode = nil)
          payload = raw

          uri = URI.parse(MaldivesPaymentGateway.notification_confirmation_url)

          request = Net::HTTP::Post.new(uri.path)

          request['Content-Length'] = "#{payload.size}"
          request['User-Agent'] = "Active Merchant -- http://activemerchant.org/"
          request['Content-Type'] = "application/x-www-form-urlencoded"

          http = Net::HTTP.new(uri.host, uri.port)
          http.verify_mode    = OpenSSL::SSL::VERIFY_NONE unless @ssl_strict
          http.use_ssl        = true

          response = http.request(request, payload)

          # Replace with the appropriate codes
          raise StandardError.new("Faulty MaldivesPaymentGateway result: #{response.body}") unless ["AUTHORISED", "DECLINED"].include?(response.body)
          response.body == "AUTHORISED"
        end

        private

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
