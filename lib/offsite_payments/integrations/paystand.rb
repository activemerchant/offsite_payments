#require 'active_utils'
#include ActiveUtils::PostsData

module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module Paystand
      mattr_accessor :service_url

      mattr_accessor :production_url
      self.production_url = 'https://app.paystand.com'

      mattr_accessor :test_url
      self.test_url = 'https://sandbox.paystand.co'

      mattr_accessor :dev_url
      self.dev_url = 'https://dev.paystand.localhost'

      mattr_accessor :service_uri
      self.service_uri = '/fcommerce/cart_checkout'

      mattr_accessor :notification_confirmation_uri
      self.notification_confirmation_uri = '/api/v2/orders'

      def self.service_url
        mode = OffsitePayments.mode
        case mode
        when :production
          self.production_url + self.service_uri
        when :test
          self.test_url + self.service_uri
        when :dev
            self.dev_url + self.service_uri
        else
          raise StandardError, "Integration mode set to an invalid value: #{mode}"
        end
      end

      def self.notification_confirmation_url
        mode = OffsitePayments.mode
        case mode
        when :production
          self.production_url + self.notification_confirmation_uri
        when :test
          self.test_url + self.notification_confirmation_uri
        when :dev
          self.dev_url + self.notification_confirmation_uri
        else
          raise StandardError, "Integration mode set to an invalid value: #{mode}"
        end
      end

      def self.notification(post)
        Notification.new(post)
      end

      class Helper < OffsitePayments::Helper

        def initialize(order, account, options = {})
          super
          add_field('checkout_type', 'www')
        end

        mapping :checkout_type, 'checkout_type'

        mapping :return_url, 'return_url'
        mapping :cancel_return_url, 'cancel_url'
        mapping :account, 'org_id'
        mapping :credential2, 'api_key'
        mapping :amount, 'pre_fee_total'
        mapping :order, 'order_id'
        mapping :currency, 'currency'

        mapping :customer, :first_name => 'first_name',
                           :last_name  => 'last_name',
                           :email      => 'email'

        mapping :billing_address,  :city    => 'city',
                                    :addres => 'address1',
                                    :address2 => 'address2',
                                    :state   => 'state',
                                    :zip     => 'zip',
                                    :country => 'country'
      end


      #
      # var psn = {
      #   'org_id': '',
      #   'txn_id': '',
      #   'recurring_id': '',
      #   'consumer_id': '',
      #   'pre_fee_total': '',
      #   'fee_merchant_owes': '',
      #   'rate_merchant_owes': '',
      #   'fee_consumer_owes': '',
      #   'rate_consumer_owes': '',
      #   'total_amount': '',
      #   'amount': '',
      #   'tax': '',
      #   'shipping_handling': '',
      #   'payment_status': '',
      #   'completion_status': '',
      #   'success': '',                //success
      #   'rail': '',                   //rail
      #   'currency': '',               //currency
      #   'order_id': '',               //account
      #   'order_token': ''
      # };
      class Notification < OffsitePayments::Notification

        include ActiveUtils::PostsData

        def complete?
          status == "paid"
        end

        def transaction_id
          params['txn_id']
        end

        def item_id
          params['order_id']
        end

        def currency
          "US"
        end

        def gross
          params['amount']
        end

        def test?
          true
        end

        def status
          params['payment_status']
        end

        # Acknowledge the transaction to Paystand. This method has to be called after a new
        # apc arrives. Paystand will verify that all the information we received are correct and will return a
        # ok or a fail.
        #
        # Example:
        #
        #   def ipn
        #     notify = PaystandNotification.new(request.raw_post)
        #
        #     if notify.acknowledge
        #       ... process order ... if notify.complete?
        #     else
        #       ... log possible hacking attempt ...
        #     end
        def acknowledge(authcode = nil)

          psn = raw.to_s
          psn_post = JSON.parse(psn)

          uri = URI.parse(Paystand.notification_confirmation_url)
          #uri = "https://intern.paystand.com/api/v2/orders"

          #puts Paystand.notification_confirmation_url

          payload ={
            :action => "verify_psn",
            :api_key => authcode,
            :order_id => psn_post['txn_id'],
            :psn => psn_post
          }.to_json

          #trying out post
          response = ssl_post(uri, payload)
          #response_body = response.body.to_s
          response_data = JSON.parse(response)

          # Replace with the appropriate codes
          raise StandardError.new("Faulty Paystand result: #{response_data['data']}") unless (response_data['data'])
          response_data['data'] == true 

        end

        private

        def parse(post)
          @raw = post.to_s
          json_post = JSON.parse(post)
          params.merge!(json_post)
        end

      end
    end
  end
end
