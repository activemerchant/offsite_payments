module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    # Documentation:
    # https://www.payfast.co.za/s/std/integration-guide
    module PayFast
      # Overwrite this if you want to change the PayFast sandbox url
      mattr_accessor :process_test_url
      self.process_test_url = 'https://sandbox.payfast.co.za/eng/process'

      # Overwrite this if you want to change the PayFast production url
      mattr_accessor :process_production_url
      self.process_production_url = 'https://www.payfast.co.za/eng/process'

      # Overwrite this if you want to change the PayFast sandbox url
      mattr_accessor :validate_test_url
      self.validate_test_url = 'https://sandbox.payfast.co.za/eng/query/validate'

      # Overwrite this if you want to change the PayFast production url
      mattr_accessor :validate_production_url
      self.validate_production_url = 'https://www.payfast.co.za/eng/query/validate'

      mattr_accessor :signature_parameter_name
      self.signature_parameter_name = 'signature'

      def self.service_url
        mode = OffsitePayments.mode
        case mode
        when :production
          self.process_production_url
        when :test
          self.process_test_url
        else
          raise StandardError, "Integration mode set to an invalid value: #{mode}"
        end
      end

      def self.validate_service_url
        mode = OffsitePayments.mode
        case mode
        when :production
          self.validate_production_url
        when :test
          self.validate_test_url
        else
          raise StandardError, "Integration mode set to an invalid value: #{mode}"
        end
      end

      def self.helper(order, account, options = {})
        Helper.new(order, account, options)
      end

      def self.notification(query_string, options = {})
        Notification.new(query_string, options)
      end

      def self.return(post, options = {})
        Return.new(post, options)
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

        def request_attributes
          [:merchant_id, :merchant_key, :return_url, :cancel_url,
           :notify_url, :name_first, :name_last, :email_address,
           :payment_id, :amount, :item_name, :item_description,
           :custom_str1, :custom_str2, :custom_str3, :custom_str4,
           :custom_str5, :custom_int1, :custom_int2, :custom_int3,
           :custom_int4, :custom_int5, :email_confirmation,
           :confirmation_address]
        end

        def request_signature_string
          request_attributes.map do |attr|
            "#{mappings[attr]}=#{CGI.escape(@fields[mappings[attr]])}" if @fields[mappings[attr]].present?
          end.compact.join('&')
        end

        def notify_signature_string
          params.map do |key, value|
            "#{key}=#{CGI.escape(value)}" unless key == PayFast.signature_parameter_name
          end.compact.join('&')
        end
      end

      class Helper < OffsitePayments::Helper
        include Common

        def initialize(order, account, options = {})
          super
          add_field('merchant_id', account)
          add_field('merchant_key', options.delete(:credential2))
          add_field('m_payment_id', order)
        end

        def form_fields
          @fields
        end

        def params
          @fields
        end

        mapping :merchant_id, 'merchant_id'
        mapping :merchant_key, 'merchant_key'
        mapping :return_url, 'return_url'
        mapping :cancel_return_url, 'cancel_url'
        mapping :notify_url, 'notify_url'
        mapping :name_first, 'name_first'
        mapping :name_last, 'name_last'
        mapping :email_address, 'email_address'
        mapping :payment_id, 'm_payment_id'
        mapping :amount, 'amount'
        mapping :item_name, 'item_name'
        mapping :description, 'item_name'

        mapping :customer, :first_name => 'name_first',
                           :last_name  => 'name_last',
                           :email      => 'email_address',
                           :phone      => 'phone'

        5.times { |i| mapping :"custom_str#{i}", "custom_str#{i}" }
        5.times { |i| mapping :"custom_int#{i}", "custom_int#{i}" }

        mapping :email_confirmation, 'email_confirmation'
        mapping :confirmation_address, 'confirmation_address'
      end

      # Parser and handler for incoming ITN from PayFast.
      # The Example shows a typical handler in a rails application.
      #
      # Example
      #
      #   class BackendController < ApplicationController
      #     include OffsitePayments::Integrations
      #
      #     def pay_fast_itn
      #       notify = PayFast::Notification.new(request.raw_post)
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
      #           order.status = 'failed'
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
        include ActiveUtils::PostsData
        include Common

        # Was the transaction complete?
        def complete?
          status == "Completed"
        end

        # Status of transaction. List of possible values:
        # <tt>COMPLETE</tt>::
        def status
          if params['payment_status'] == "COMPLETE"
            "Completed"
          else
            "Failed"
          end
        end

        # Id of this transaction (uniq PayFast transaction id)
        def transaction_id
          params['pf_payment_id']
        end

        # Id of this transaction (uniq Shopify transaction id)
        def item_id
          params['m_payment_id']
        end

        # The total amount which the payer paid.
        def gross
          params['amount_gross']
        end

        # The total in fees which was deducted from the amount.
        def fee
          params['amount_fee']
        end

        # The net amount credited to the receiver's account.
        def amount
          Money.from_amount(BigDecimal.new(params['amount_net']), currency)
        end

        # The name of the item being charged for.
        def item_name
          params['item_name']
        end

        # The Merchant ID as given by the PayFast system. Used to uniquely identify the receiver's account.
        def merchant_id
          params['merchant_id']
        end

        def currency
          'ZAR'
        end

        # Generated hash depends on params order so use OrderedHash instead of Hash
        def empty!
          super
          @params  = ActiveSupport::OrderedHash.new
        end

        # Acknowledge the transaction to PayFast. This method has to be called after a new
        # ITN arrives. PayFast will verify that all the information we received are correct and will return a
        # VERIFIED or INVALID status.
        #
        # Example:
        #
        #   def pay_fast_itn
        #     notify = PayFastNotification.new(request.raw_post)
        #
        #     if notify.acknowledge
        #       ... process order ... if notify.complete?
        #     else
        #       ... log possible hacking attempt ...
        #     end
        def acknowledge(authcode = nil)
          if params[PayFast.signature_parameter_name] == generate_signature(:notify)
            response = ssl_post(PayFast.validate_service_url, notify_signature_string,
              'Content-Type' => "application/x-www-form-urlencoded",
              'Content-Length' => "#{notify_signature_string.size}"
            )
            raise StandardError.new("Faulty PayFast result: #{response}") unless ['VALID', 'INVALID'].include?(response)

            response == "VALID"
          end
        end
      end

      class Return < OffsitePayments::Return
      end
    end
  end
end
