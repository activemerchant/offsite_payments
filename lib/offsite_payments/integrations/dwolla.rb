module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module Dwolla
      mattr_accessor :service_url
      self.service_url = 'https://www.dwolla.com/payment/pay'

      def self.notification(post, options={})
        Notification.new(post, options)
      end

      def self.return(query_string, options={})
        Return.new(query_string, options)
      end

      module Common
        def verify_signature(checkoutId, amount, notification_signature, secret)
          if secret.nil?
            raise ArgumentError, "You need to provide the Application secret as the option :credential3 to verify that the notification originated from Dwolla"
          end

          expected_signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA1.new, secret, "%s&%.2f" % [checkoutId, amount])

          if notification_signature != expected_signature
            raise StandardError, "Dwolla signature verification failed."
          end
        end
      end

      class Helper < OffsitePayments::Helper
        def initialize(order, account, options = {})
          super
          add_field('name', 'Store Purchase')

          timestamp = Time.now.to_i.to_s

          if OffsitePayments.mode == :test || options[:test]
            add_field('test', 'true')
            # timestamp used for test signature generation:
            timestamp = "1370726016"
          end

          add_field('timestamp', timestamp)
          add_field('allowFundingSources', 'true')

          key = options[:credential2].to_s
          secret = options[:credential3].to_s
          orderid = order.to_s
          signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA1.new, secret, "#{key}&#{timestamp}&#{orderid}")
          add_field('signature', signature)
        end

        mapping :account, 'destinationid'
        mapping :credential2, 'key'
        mapping :notify_url, 'callback'
        mapping :return_url, 'redirect'
        mapping :description, 'description'
        mapping :amount, 'amount'
        mapping :tax, 'tax'
        mapping :shipping, 'shipping'
        mapping :order, 'orderid'
      end

      class Notification < OffsitePayments::Notification
        include Common

        def initialize(data, options)
          super
        end

        def complete?
          (status == "Completed")
        end

        def status
          params["Status"]
        end

        def transaction_id
          params['TransactionId']
        end

        def item_id
          params['OrderId']
        end

        def currency
          "USD"
        end

        def gross
          params['Amount']
        end

        def error
          params['Error']
        end

        def test?
          params['TestMode'] != "false"
        end

        def acknowledge(authcode = nil)
          true
        end

        private

        def parse(post)
          @raw = post.to_s
          json_post = JSON.parse(post)
          verify_signature(json_post['CheckoutId'], json_post['Amount'], json_post['Signature'], @options[:credential3])

          params.merge!(json_post)
        end
      end

      class Return < OffsitePayments::Return
        include Common

        def initialize(data, options)
          params = parse(data)

          if params['error'] != 'failure'
            verify_signature(params['checkoutId'], params['amount'], params['signature'], options[:credential3])
          end

          super
        end

        def success?
          (self.error.nil? && self.callback_success?)
        end

        def error
          params['error']
        end

        def error_description
          params['error_description']
        end

        def checkout_id
          params['checkoutId']
        end

        def transaction
          params['transaction']
        end

        def test?
          params['test'] != nil
        end

        def callback_success?
          (params['postback'] != "failure")
        end
      end
    end
  end
end
