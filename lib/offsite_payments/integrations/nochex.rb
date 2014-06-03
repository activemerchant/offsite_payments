module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    # To start with Nochex, follow the instructions for installing
    # ActiveMerchant as a plugin, as described on
    # http://www.activemerchant.org/.
    #
    # The plugin will automatically add the ActionView helper for
    # ActiveMerchant, which will allow you to make the Nochex payments.
    # The idea behind the helper is that it generates an invisible
    # forwarding screen that will automatically redirect the user.
    # So you would collect all the information about the order and then
    # simply render the hidden form, which redirects the user to Nochex.
    #
    # The syntax of the helper is as follows:
    #
    #   <% payment_service_for 'order id', 'nochex_user_id',
    #                                 :amount => 50.00,
    #                                 :service => :nochex,
    #                                 :html => { :id => 'nochex-form' } do |service| %>
    #
    #      <% service.customer :first_name => 'Cody',
    #                         :last_name => 'Fauser',
    #                         :phone => '(555)555-5555',
    #                         :email => 'cody@example.com' %>
    #
    #      <% service.billing_address :city => 'Ottawa',
    #                                :address1 => '21 Snowy Brook Lane',
    #                                :address2 => 'Apt. 36',
    #                                :state => 'ON',
    #                                :country => 'CA',
    #                                :zip => 'K1J1E5' %>
    #
    #      <% service.invoice '#1000' %>
    #      <% service.shipping '0.00' %>
    #      <% service.tax '0.00' %>
    #
    #      <% service.notify_url url_for(:action => 'notify', :only_path => false) %>
    #      <% service.return_url url_for(:action => 'done', :only_path => false) %>
    #      <% service.cancel_return_url 'http://mystore.com' %>
    #    <% end %>
    #
    # The notify_url is the URL that the Nochex IPN will be sent.  You can
    # handle the notification in your controller action as follows:
    #
    #   class NotificationController < ApplicationController
    #     include OffsitePayments::Integrations
    #
    #     def notify
    #       notification =  Nochex::Notification.new(request.raw_post)
    #
    #       begin
    #         # Acknowledge notification with Nochex
    #         raise StandardError, 'Illegal Notification' unless notification.acknowledge
    #           # Process the payment
    #       rescue => e
    #           logger.warn("Illegal notification received: #{e.message}")
    #       ensure
    #           head(:ok)
    #       end
    #     end
    #   end
    module Nochex
      mattr_accessor :service_url
      self.service_url = 'https://secure.nochex.com'

      mattr_accessor :notification_confirmation_url
      self.notification_confirmation_url = 'https://www.nochex.com/nochex.dll/apc/apc'

      # Simply a convenience method that returns a new
      # OffsitePayments::Integrations::Nochex::Notification
      def self.notification(post, options = {})
        Notification.new(post)
      end

      def self.return(query_string, options = {})
        Return.new(query_string)
      end

      class Helper < OffsitePayments::Helper
        # Required Parameters
        # email
        # amount
        mapping :account, 'email'
        mapping :amount, 'amount'

        # Set the field status = test for testing with accounts:
        # Account             Password
        # test1@nochex.com    123456
        # test2@nochex.com    123456
        # def initialize(order, account, options = {})
        #  super
        #  add_field('status', 'test')
        # end

        # Need to format the amount to have 2 decimal places
        def amount=(money)
          cents = money.respond_to?(:cents) ? money.cents : money
          raise ArgumentError, "amount must be a Money object or an integer" if money.is_a?(String)
          raise ActionViewHelperError, "amount must be greater than $0.00" if cents.to_i <= 0

          add_field mappings[:amount], sprintf("%.2f", cents.to_f/100)
        end

        # Optional Parameters
        # ordernumber
        mapping :order, 'ordernumber'

        # firstname
        # lastname
        # email_address_sender
        mapping :customer, :first_name => 'firstname',
                           :last_name  => 'lastname',
                           :email      => 'email_address_sender'

        # town
        # firstline
        # county
        # postcode
        mapping :billing_address, :city     => 'town',
                                  :address1 => 'firstline',
                                  :state    => 'county',
                                  :zip      => 'postcode'

        # responderurl
        mapping :notify_url, 'responderurl'

        # returnurl
        mapping :return_url, 'returnurl'

        # cancelurl
        mapping :cancel_return_url, 'cancelurl'

        # description
        mapping :description, 'description'

        # Currently unmapped
        # logo
      end

      # Parser and handler for incoming Automatic Payment Confirmations from Nochex.
      class Notification < OffsitePayments::Notification
        include ActiveMerchant::PostsData

        def complete?
          status == 'Completed'
        end

        # Id of the order we passed to Nochex
        def item_id
          params['order_id']
        end

        def transaction_id
          params['transaction_id']
        end

        def currency
          'GBP'
        end

        # When was this payment received by the client.
        def received_at
          # U.K. Format: 27/09/2006 22:30:54
          return if params['transaction_date'].blank?
          time = params['transaction_date'].scan(/\d+/)
          Time.utc(time[2], time[1], time[0], time[3], time[4], time[5])
        end

        def payer_email
          params['from_email']
        end

        def receiver_email
          params['to_email']
        end

        def security_key
          params['security_key']
        end

        # the money amount we received in X.2 decimal.
        def gross
          sprintf("%.2f", params['amount'].to_f)
        end

        # Was this a test transaction?
        def test?
          params['status'] == 'test'
        end

        def status
          'Completed'
        end

        # Acknowledge the transaction to Nochex. This method has to be called after a new
        # apc arrives. Nochex will verify that all the information we received are correct and will return a
        # ok or a fail. This is very similar to the PayPal IPN scheme.
        #
        # Example:
        #
        #   def nochex_ipn
        #     notify = NochexNotification.new(request.raw_post)
        #
        #     if notify.acknowledge
        #       ... process order ... if notify.complete?
        #     else
        #       ... log possible hacking attempt ...
        #     end
        def acknowledge(authcode = nil)
           payload =  raw

           response = ssl_post(Nochex.notification_confirmation_url, payload,
             'Content-Length' => "#{payload.size}",
             'User-Agent'     => "Active Merchant -- http://activemerchant.org",
             'Content-Type'   => "application/x-www-form-urlencoded"
           )

           raise StandardError.new("Faulty Nochex result: #{response}") unless ["AUTHORISED", "DECLINED"].include?(response)

           response == "AUTHORISED"
        end
      end

      class Return < OffsitePayments::Return
      end
    end
  end
end
