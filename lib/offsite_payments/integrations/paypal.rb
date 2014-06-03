module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module Paypal
      # Overwrite this if you want to change the Paypal test url
      mattr_accessor :test_url
      self.test_url = 'https://www.sandbox.paypal.com/cgi-bin/webscr'

      # Overwrite this if you want to change the Paypal production url
      mattr_accessor :production_url
      self.production_url = 'https://www.paypal.com/cgi-bin/webscr'

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

      def self.notification(post, options = {})
        Notification.new(post)
      end

      def self.return(query_string, options = {})
        Return.new(query_string)
      end

      class Helper < OffsitePayments::Helper
       CANADIAN_PROVINCES = {  'AB' => 'Alberta',
                               'BC' => 'British Columbia',
                               'MB' => 'Manitoba',
                               'NB' => 'New Brunswick',
                               'NL' => 'Newfoundland',
                               'NS' => 'Nova Scotia',
                               'NU' => 'Nunavut',
                               'NT' => 'Northwest Territories',
                               'ON' => 'Ontario',
                               'PE' => 'Prince Edward Island',
                               'QC' => 'Quebec',
                               'SK' => 'Saskatchewan',
                               'YT' => 'Yukon'
                             }
        # See https://www.paypal.com/IntegrationCenter/ic_std-variable-reference.html for details on the following options.
        mapping :order, [ 'item_number', 'custom' ]

        def initialize(order, account, options = {})
          super
          add_field('cmd', '_ext-enter')
          add_field('redirect_cmd', '_xclick')
          add_field('quantity', 1)
          add_field('item_name', 'Store purchase')
          add_field('no_shipping', '1')
          add_field('no_note', '1')
          add_field('charset', 'utf-8')
          add_field('address_override', '0')
          add_field('bn', application_id.to_s.slice(0,32)) unless application_id.blank?
        end

        mapping :amount, 'amount'
        mapping :account, 'business'
        mapping :currency, 'currency_code'
        mapping :notify_url, 'notify_url'
        mapping :return_url, 'return'
        mapping :cancel_return_url, 'cancel_return'
        mapping :invoice, 'invoice'
        mapping :item_name, 'item_name'
        mapping :quantity, 'quantity'
        mapping :no_shipping, 'no_shipping'
        mapping :no_note, 'no_note'
        mapping :address_override, 'address_override'

        mapping :application_id, 'bn'

        mapping :customer, :first_name => 'first_name',
                           :last_name  => 'last_name',
                           :email      => 'email'

        mapping :shipping_address,  :city    => 'city',
                                    :address1 => 'address1',
                                    :address2 => 'address2',
                                    :state   => 'state',
                                    :zip     => 'zip',
                                    :country => 'country'

        def shipping_address(params = {})
          # Get the country code in the correct format
          # Use what we were given if we can't find anything
          country_code = lookup_country_code(params.delete(:country))
          add_field(mappings[:shipping_address][:country], country_code)

          if params.has_key?(:phone)
            phone = params.delete(:phone).to_s

            # Wipe all non digits
            phone.gsub!(/\D+/, '')

            if ['US', 'CA'].include?(country_code) && phone =~ /(\d{3})(\d{3})(\d{4})$/
              add_field('night_phone_a', $1)
              add_field('night_phone_b', $2)
              add_field('night_phone_c', $3)
            else
              add_field('night_phone_b', phone)
            end
          end

          province_code = params.delete(:state)

          case country_code
          when 'CA'
            add_field(mappings[:shipping_address][:state], CANADIAN_PROVINCES[province_code.upcase]) unless province_code.nil?
          when 'US'
            add_field(mappings[:shipping_address][:state], province_code)
          else
            add_field(mappings[:shipping_address][:state], province_code.blank? ? 'N/A' : province_code)
          end

          # Everything else
          params.each do |k, v|
            field = mappings[:shipping_address][k]
            add_field(field, v) unless field.nil?
          end
        end

        mapping :tax, 'tax'
        mapping :shipping, 'shipping'
        mapping :cmd, 'cmd'
        mapping :custom, 'custom'
        mapping :src, 'src'
        mapping :sra, 'sra'
        %w(a p t).each do |l|
          (1..3).each do |i|
            mapping "#{l}#{i}".to_sym, "#{l}#{i}"
          end
        end
      end

      # Parser and handler for incoming Instant payment notifications from paypal.
      # The Example shows a typical handler in a rails application. Note that this
      # is an example, please read the Paypal API documentation for all the details
      # on creating a safe payment controller.
      #
      # Example
      #
      #   class BackendController < ApplicationController
      #     include OffsitePayments::Integrations
      #
      #     def paypal_ipn
      #       notify = Paypal::Notification.new(request.raw_post)
      #
      #       if notify.masspay?
      #         masspay_items = notify.items
      #       end
      #
      #       order = Order.find(notify.item_id)
      #
      #       if notify.acknowledge
      #         begin
      #
      #           if notify.complete? and order.total == notify.amount
      #             order.status = 'success'
      #
      #             shop.ship(order)
      #           else
      #             logger.error("Failed to verify Paypal's notification, please investigate")
      #           end
      #
      #         rescue => e
      #           order.status        = 'failed'
      #           raise
      #         ensure
      #           order.save
      #         end
      #       end
      #
      #       render :nothing
      #     end
      #   end
      class Notification < OffsitePayments::Notification
        include ActiveMerchant::PostsData

        def initialize(post, options = {})
          super
          extend MassPayNotification if masspay?
        end

        # Was the transaction complete?
        def complete?
          status == "Completed"
        end

        # Is it a masspay notification?
        def masspay?
          type == "masspay"
        end

        # When was this payment received by the client.
        # sometimes it can happen that we get the notification much later.
        # One possible scenario is that our web application was down. In this case paypal tries several
        # times an hour to inform us about the notification
        def received_at
          parsed_time_fields = DateTime._strptime(params['payment_date'], "%H:%M:%S %b %d, %Y %Z")
          Time.gm(
            parsed_time_fields[:year],
            parsed_time_fields[:mon],
            parsed_time_fields[:mday],
            parsed_time_fields[:hour],
            parsed_time_fields[:min],
            parsed_time_fields[:sec]
          ) - Time.zone_offset(parsed_time_fields[:zone])
        end

        # Status of transaction. List of possible values:
        # <tt>Canceled-Reversal</tt>::
        # <tt>Completed</tt>::
        # <tt>Denied</tt>::
        # <tt>Expired</tt>::
        # <tt>Failed</tt>::
        # <tt>In-Progress</tt>::
        # <tt>Partially-Refunded</tt>::
        # <tt>Pending</tt>::
        # <tt>Processed</tt>::
        # <tt>Refunded</tt>::
        # <tt>Reversed</tt>::
        # <tt>Voided</tt>::
        def status
          params['payment_status']
        end

        # Id of this transaction (paypal number)
        def transaction_id
          params['txn_id']
        end

        # What type of transaction are we dealing with?
        #  "cart" "send_money" "web_accept" are possible here.
        def type
          params['txn_type']
        end

        # the money amount we received in X.2 decimal.
        def gross
          params['mc_gross']
        end

        # the markup paypal charges for the transaction
        def fee
          params['mc_fee']
        end

        # What currency have we been dealing with
        def currency
          params['mc_currency']
        end

        # This is the item number which we submitted to paypal
        # The custom field is also mapped to item_id because PayPal
        # doesn't return item_number in dispute notifications
        def item_id
          params['item_number'] || params['custom']
        end

        # This is the invoice which you passed to paypal
        def invoice
          params['invoice']
        end

        # Was this a test transaction?
        def test?
          params['test_ipn'] == '1'
        end

        def account
          params['business'] || params['receiver_email']
        end

        # Acknowledge the transaction to paypal. This method has to be called after a new
        # ipn arrives. Paypal will verify that all the information we received are correct and will return a
        # ok or a fail.
        #
        # Example:
        #
        #   def paypal_ipn
        #     notify = PaypalNotification.new(request.raw_post)
        #
        #     if notify.acknowledge
        #       ... process order ... if notify.complete?
        #     else
        #       ... log possible hacking attempt ...
        #     end
        def acknowledge(authcode = nil)
          payload =  raw

          response = ssl_post(Paypal.service_url + '?cmd=_notify-validate', payload,
            'Content-Length' => "#{payload.size}",
            'User-Agent'     => "Active Merchant -- http://activemerchant.org"
          )

          raise StandardError.new("Faulty paypal result: #{response}") unless ["VERIFIED", "INVALID"].include?(response)

          response == "VERIFIED"
        end
      end

      module MassPayNotification
        # Mass pay returns a collection of MassPay Items, so inspect items to get the values
        def transaction_id
        end

        # Mass pay returns a collection of MassPay Items, so inspect items to get the values
        def gross
        end

        # Mass pay returns a collection of MassPay Items, so inspect items to get the values
        def fee
        end

        # Mass pay returns a collection of MassPay Items, so inspect items to get the values
        def currency
        end

        # Mass pay returns a collection of MassPay Items, so inspect items to get the values
        def item_id
        end

        # Mass pay returns a collection of MassPay Items, so inspect items to get the values
        def account
        end

        # Collection of notification items returned for MassPay transactions
        def items
          @items ||= (1..number_of_mass_pay_items).map do |item_number|
            MassPayItem.new(
              params["masspay_txn_id_#{item_number}"],
              params["mc_gross_#{item_number}"],
              params["mc_fee_#{item_number}"],
              params["mc_currency_#{item_number}"],
              params["unique_id_#{item_number}"],
              params["receiver_email_#{item_number}"],
              params["status_#{item_number}"]
            )
          end
        end

        private

        def number_of_mass_pay_items
          @number_of_mass_pay_items ||= params.keys.select { |k| k.start_with? 'masspay_txn_id' }.size
        end
      end

      class MassPayItem < Struct.new(:transaction_id, :gross, :fee, :currency, :item_id, :account, :status)
      end

      class Return < OffsitePayments::Return
      end
    end
  end
end
