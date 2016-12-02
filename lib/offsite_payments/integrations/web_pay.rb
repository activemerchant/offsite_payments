module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    # Documentation: You will get it after registration steps here:
    # http://reg.webpay.by/registration-form.php
    module WebPay
      # Overwrite this if you want to change the WebPay sandbox url
      mattr_accessor :test_url
      self.test_url = 'https://secure.sandbox.webpay.by:8843'

      # Overwrite this if you want to change the WebPay production url
      mattr_accessor :production_url
      self.production_url = 'https://secure.webpay.by'

      mattr_accessor :signature_parameter_name
      self.signature_parameter_name = 'wsb_signature'

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

      def self.helper(order, account, options = {})
        Helper.new(order, account, options)
      end

      def self.notification(query_string, options = {})
        Notification.new(query_string, options)
      end

      module Common
        def generate_signature(type)
          string = case type
          when :request
            request_signature_string
          when :notify
            notify_signature_string
          end
          if type != :notify && @fields[mappings[:version]] == '2'
            Digest::SHA1.hexdigest(string)
          else
            Digest::MD5.hexdigest(string)
          end
        end

        def request_signature_string
          [
            @fields[mappings[:seed]],
            @fields[mappings[:account]],
            @fields[mappings[:order]],
            @fields[mappings[:test]],
            @fields[mappings[:currency]],
            @fields[mappings[:amount]],
            secret
          ].join
        end

        def notify_signature_string
          [
            params['batch_timestamp'],
            params['currency_id'],
            params['amount'],
            params['payment_method'],
            params['order_id'],
            params['site_order_id'],
            params['transaction_id'],
            params['payment_type'],
            params['rrn'],
            secret
          ].join
        end
      end

      class Helper < OffsitePayments::Helper
        include Common

        def initialize(order, account, options = {})
          @md5secret = options.delete(:secret)
          @line_item_count = 0
          super
        end

        def form_fields
          @fields.merge(OffsitePayments::Integrations::WebPay.signature_parameter_name => generate_signature(:request))
        end

        def params
          @fields
        end

        def secret
          @md5secret
        end

        def add_line_item(options)
          options.each do |key, value|
            add_field("wsb_invoice_item_#{key}[#{@line_item_count}]", value)
          end

          @line_item_count += 1
        end

        def calculate_total
          sum = 0

          @line_item_count.times do |i|
            sum += @fields["wsb_invoice_item_quantity[#{i}]"].to_i * @fields["wsb_invoice_item_price[#{i}]"].to_i
          end

          sum + @fields[mappings[:tax]].to_i + @fields[mappings[:shipping_price]].to_i - @fields[mappings[:discount_price]].to_i
        end

        mapping :scart, '*scart'
        mapping :account, 'wsb_storeid'
        mapping :store, 'wsb_store'
        mapping :order, 'wsb_order_num'
        mapping :currency, 'wsb_currency_id'
        mapping :version, 'wsb_version'
        mapping :language, 'wsb_language_id'
        mapping :seed, 'wsb_seed'
        mapping :success_url, 'wsb_return_url'
        mapping :cancel_url, 'wsb_cancel_return_url'
        mapping :notify_url, 'wsb_notify_url'
        mapping :test, 'wsb_test'
        mapping :tax, 'wsb_tax'
        mapping :shipping_name, 'wsb_shipping_name'
        mapping :shipping_price, 'wsb_shipping_price'
        mapping :discount_name, 'wsb_discount_name'
        mapping :discount_price, 'wsb_discount_price'
        mapping :amount, 'wsb_total'
        mapping :email, 'wsb_email'
        mapping :phone, 'wsb_phone'
      end

      class Notification < OffsitePayments::Notification
        include Common

        def self.recognizes?(params)
          params.has_key?('site_order_id') && params.has_key?('amount')
        end

        def complete?
          true
        end

        def amount
          Money.from_amount(BigDecimal.new(gross), currency)
        end

        def item_id
          params['site_order_id']
        end

        def security_key
          params[OffsitePayments::Integrations::WebPay.signature_parameter_name]
        end

        def gross
          params['amount']
        end

        def status
          'success'
        end

        def secret
          @options[:secret]
        end

        def acknowledge(authcode = nil)
          (security_key == generate_signature(:notify))
        end

        def success_response(*args)
          {:nothing => true}
        end

        def currency
          params['currency_id']
        end
      end
    end
  end
end
