module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module Klarna
      mattr_accessor :service_url
      self.service_url = 'https://hpp-test.herokuapp.com/shopify/payment'

      REQUIRED_FIELDS = %w(amount checkout_token merchant_base_uri merchant_checkout_uri merchant_confirmation_uri merchant_id merchant_terms_uri purchase_currency)

      def self.notification(post_body, options = {})
        Notification.new(post_body, options)
      end

      def self.return(query_string, options = {})
        Return.new(query_string, options)
      end

      def self.cart_items_payload(fields, cart_items)
        check_required_fields!(fields)

        payload = ""
        REQUIRED_FIELDS.sort.each do |field|
           payload << fields[field].to_s
        end

        payload
      end

      def self.sign(fields, cart_items, shared_secret)
        payload = cart_items_payload(fields, cart_items)

        digest(payload, shared_secret)
      end

      def self.digest(payload, shared_secret)
        Digest::SHA256.base64digest(payload + shared_secret.to_s)
      end

      private

      def self.check_required_fields!(fields)
        REQUIRED_FIELDS.each do |required_field|
          raise ArgumentError, "Missing required field #{required_field}" if fields[required_field].nil?
        end
      end

      class Helper < OffsitePayments::Helper
        mapping :currency, 'purchase_currency'
        mapping :cancel_return_url, ['merchant_terms_uri', 'merchant_checkout_uri', 'merchant_base_uri']
        mapping :account, 'merchant_id'
        mapping :customer, email: 'shipping_address_email'
        mapping :checkout_token, 'checkout_token'
        mapping :amount, 'amount'

        def initialize(order, account, options = {})
          super
          @shared_secret = options[:credential2]
          @order = order

          add_field('platform_type', application_id)
          add_field('test_mode', test?.to_s)
        end

        def notify_url(url)
          url = append_order_query_param(url)
          add_field('merchant_push_uri', url)
        end

        def return_url(url)
          url = append_order_query_param(url)
          add_field('merchant_confirmation_uri', url)
        end

        def line_item(item)
          @line_items ||= []
          @line_items << item

          i = @line_items.size - 1

          add_field("cart_item-#{i}_type", type_for(item))
          add_field("cart_item-#{i}_reference", item.fetch(:reference, ''))
          add_field("cart_item-#{i}_name", item.fetch(:name, ''))
          add_field("cart_item-#{i}_quantity", item.fetch(:quantity, ''))
          add_field("cart_item-#{i}_unit_price", tax_included_unit_price(item)).to_s
          add_field("cart_item-#{i}_discount_rate", item.fetch(:discount_rate, ''))
          add_field("cart_item-#{i}_tax_rate", tax_rate_for(item)).to_s

          @fields
        end

        def billing_address(billing_fields)
          country = billing_fields[:country]

          add_field('purchase_country', country)
          add_field('locale', guess_locale_based_on_country(country))
        end

        def shipping_address(shipping_fields)
          add_field('shipping_address_given_name', shipping_fields[:first_name])
          add_field('shipping_address_family_name', shipping_fields[:last_name])

          street_address = [shipping_fields[:address1], shipping_fields[:address2]].compact.join(', ')
          add_field('shipping_address_street_address', street_address)

          add_field('shipping_address_postal_code', shipping_fields[:zip])
          add_field('shipping_address_city', shipping_fields[:city])
          add_field('shipping_address_country', shipping_fields[:country])
          add_field('shipping_address_phone', shipping_fields[:phone])
        end

        def form_fields
          sign_fields

          super
        end

        def sign_fields
          merchant_digest = Klarna.sign(@fields, @line_items, @shared_secret)
          add_field('merchant_digest', merchant_digest)
        end

        private

        def type_for(item)
          case item.fetch(:type, '')
          when 'shipping'
            'shipping_fee'
          when 'line item'
            'physical'
          when 'discount'
            'discount'
          else
            raise StandardError, "Unable to determine type for item #{item.to_yaml}"
          end
        end

        def append_order_query_param(url)
          u = URI.parse(url)
          params = Rack::Utils.parse_nested_query(u.query)
          params["order"] = @order
          u.query = params.to_query

          u.to_s
        end

        def guess_locale_based_on_country(country_code)
          case country_code
          when /no/i
            "nb-no"
          when /fi/i
            "fi-fi"
          when /se/i
            "sv-se"
          else
            "sv-se"
          end
        end

        def tax_included_unit_price(item)
          item.fetch(:unit_price, '').to_i + item.fetch(:tax_amount, '').to_i
        end

        def tax_rate_for(item)
          subtotal_price = item.fetch(:unit_price, 0).to_f * item.fetch(:quantity, 0).to_i
          tax_amount = item.fetch(:tax_amount, 0).to_f

          if subtotal_price > 0
            tax_rate = tax_amount / subtotal_price
            tax_rate = tax_rate.round(4)

            percentage_to_two_decimal_precision_whole_number(tax_rate)
          else
            0
          end
        end

        def percentage_to_two_decimal_precision_whole_number(percentage)
          (percentage * 10000).to_i
        end
      end

      class Notification < OffsitePayments::Notification
        def initialize(post, options = {})
          super
          @shared_secret = @options[:credential2]
        end

        def complete?
          status == 'Completed'
        end

        def item_id
          order
        end

        def transaction_id
          params["reference"]
        end

        def received_at
          params["completed_at"]
        end

        def payer_email
          params["billing_address"]["email"]
        end

        def receiver_email
          params["shipping_address"]["email"]
        end

        def currency
          params["purchase_currency"].upcase
        end

        def gross
          amount = Float(gross_cents) / 100
          sprintf("%.2f", amount)
        end

        def gross_cents
          params["cart"]["total_price_including_tax"]
        end

        def status
          case params['status']
          when 'checkout_complete'
            'Completed'
          else
            params['status']
          end
        end

        def acknowledge(authcode = nil)
          Verifier.new(@options[:authorization_header], @raw, @shared_secret).verify
        end

        private

        def order
          query = Rack::Utils.parse_nested_query(@options[:query_string])
          query["order"]
        end

        def parse(post)
          @raw = post.to_s
          @params = JSON.parse(post)
        end

        class Verifier
          attr_reader :header, :payload, :digest, :shared_secret
          def initialize(header, payload, shared_secret)
            @header, @payload, @shared_secret = header, payload, shared_secret

            @digest = extract_digest
          end

          def verify
            digest_matches?
          end

          private

          def extract_digest
            match = header.match(/^Klarna (?<digest>.+)$/)
            match && match[:digest]
          end

          def digest_matches?
            Klarna.digest(payload, shared_secret) == digest
          end
        end
      end
    end
  end
end
