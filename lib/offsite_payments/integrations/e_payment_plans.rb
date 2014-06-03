module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module EPaymentPlans
      mattr_accessor :production_url
      self.production_url = 'https://www.epaymentplans.com'

      mattr_accessor :test_url
      self.test_url = 'https://test.epaymentplans.com'

      def self.service_url
        mode = OffsitePayments.mode
        case mode
        when :production
          "#{production_url}/order/purchase"
        when :test
          "#{test_url}/order/purchase"
        else
          raise StandardError, "Integration mode set to an invalid value: #{mode}"
        end
      end

      def self.notification_confirmation_url
        mode = OffsitePayments.mode
        case mode
        when :production
          "#{production_url}/order/confirmation"
        when :test
          "#{test_url}/order/confirmation"
        else
          raise StandardError, "Integration mode set to an invalid value: #{mode}"
        end
      end

      def self.notification(post, options = {})
        Notification.new(post, options)
      end

      def self.return(query_string, options = {})
        Return.new(query_string, options)
      end

      class Helper < OffsitePayments::Helper
        mapping :account, 'order[account]'
        mapping :amount, 'order[amount]'

        mapping :order, 'order[num]'

        mapping :customer, :first_name => 'order[first_name]',
                           :last_name  => 'order[last_name]',
                           :email      => 'order[email]',
                           :phone      => 'order[phone]'

        mapping :billing_address, :city     => 'order[city]',
                                  :address1 => 'order[address1]',
                                  :address2 => 'order[address2]',
                                  :company  => 'order[company]',
                                  :state    => 'order[state]',
                                  :zip      => 'order[zip]',
                                  :country  => 'order[country]'

        mapping :notify_url, 'order[notify_url]'
        mapping :return_url, 'order[return_url]'
        mapping :cancel_return_url, 'order[cancel_return_url]'
        mapping :description, 'order[description]'
        mapping :tax, 'order[tax]'
        mapping :shipping, 'order[shipping]'
      end

      class Notification < OffsitePayments::Notification
        include ActiveMerchant::PostsData
        def complete?
          status == "Completed"
        end

        def transaction_id
          params['transaction_id']
        end

        def item_id
          params['item_id']
        end

        # When was this payment received by the client.
        def received_at
          Time.parse(params['received_at'].to_s).utc
        end

        def gross
          params['gross']
        end

        def currency
          params['currency']
        end

        def security_key
          params['security_key']
        end

        # Was this a test transaction?
        def test?
          params['test'] == 'test'
        end

        def status
          params['status'].capitalize
        end

        # Acknowledge the transaction to EPaymentPlans. This method has to be called after a new
        # apc arrives. EPaymentPlans will verify that all the information we received are correct
        # and will return ok or a fail.
        #
        # Example:
        #
        #   def ipn
        #     notify = EPaymentPlans.notification(request.raw_post)
        #
        #     if notify.acknowledge
        #       ... process order ... if notify.complete?
        #     else
        #       ... log possible hacking attempt ...
        #     end
        def acknowledge(authcode = nil)
          payload = raw

          response = ssl_post(EPaymentPlans.notification_confirmation_url, payload)

          # Replace with the appropriate codes
          raise StandardError.new("Faulty EPaymentPlans result: #{response}") unless ["AUTHORISED", "DECLINED"].include?(response)
          response == "AUTHORISED"
        end

        private

        # Take the posted data and move the relevant data into a hash
        def parse(post)
          @raw = post
          for line in post.split('&')
            key, value = *line.scan( %r{^(\w+)\=(.*)$} ).flatten
            params[key] = value
          end
        end
      end
    end
  end
end
