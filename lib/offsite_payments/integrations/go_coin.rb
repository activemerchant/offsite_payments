module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module GoCoin

      def self.create_invoice_url(merchant_id)
        "https://api.gocoin.com/api/v1/merchants/#{merchant_id}/invoices"
      end

      def self.read_invoice_url_prefix
        "https://api.gocoin.com/api/v1/invoices"
      end

      def self.credential_based_url(options)
        "https://gateway.gocoin.com/merchant/#{options[:account_name]}/invoices"
      end

      def self.notification(post, options = {})
        Notification.new(post, options)
      end

      def self.helper(order, account, options = {})
        Helper.new(order, account, options)
      end

      def self.return(query_string, options = {})
        Return.new(query_string)
      end

      class Helper < OffsitePayments::Helper
        def initialize(order, account, options)
          @access_token = options[:authcode]
          @currency = options[:currency] || 'USD'
          @crypto_currency = options[:crypto_currency] || 'BTC'
          @merchant_id = options[:account_name]
          super
        end

        mapping :amount, 'base_price'
        mapping :order, 'order_id'
        mapping :currency, 'base_price_currency'

        mapping :customer, :first_name => 'customer_name',
                           :email      => 'customer_email',
                           :phone      => 'customer_phone'

        mapping :billing_address, :city     => 'customer_city',
                                  :address1 => 'customer_address_1',
                                  :address2 => 'customer_address_2',
                                  :state    => 'customer_region',
                                  :zip      => 'customer_postal_code',
                                  :country  => 'customer_country'

        mapping :notify_url, 'callback_url'
        mapping :return_url, 'redirect_url'

        def form_method
          "GET"
        end

        def form_fields
          invoice = create_invoice
          raise StandardError, "Invalid response while retrieving GoCoin Invoice ID. Please try again." unless invoice
          {"invoice_id" => invoice['id']}
        end

        private

        def create_invoice
          uri = URI.parse(GoCoin.create_invoice_url(@merchant_id))
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          request = Net::HTTP::Post.new(uri.request_uri)
          request.content_type = "application/json"
          @fields['base_price_currency'] = @currency
          @fields['price_currency'] = @crypto_currency
          request.body = @fields.to_json
          request.add_field("Authorization", "Bearer #{@access_token}")
          response = http.request(request)
          JSON.parse(response.body)
        rescue JSON::ParserError
        end
      end

      class Notification < OffsitePayments::Notification
          def complete?
            status == 'ready_to_ship'
          end

          def status
            params['payload']['status']
          end

          # GoCoin Event ID
          def transaction_id
            params['id']
          end

          # GoCoin Invoice ID
          def item_id
            params['payload']['id']
          end

          # Time GoCoin server generated callback
          def received_at
            Time.parse(params['payload']['server_time']) rescue return nil
          end

          # Base currency invoice was created with
          def currency
            params['payload']['base_price_currency']
          end

          # Crypto currency invoice was actually paid in
          def crypto_currency
            params['payload']['price_currency']
          end

          # Gross amount of the invoice in base currency
          def gross
            BigDecimal.new(params['payload']['base_price'], 8)
          end

          # Gross amount charged to customer in crypto-currency
          def crypto_gross
            BigDecimal.new(params['payload']['price'], 8)
          end

          # Hits the GoCoin API to get the invoice and compare the data
          def acknowledge(access_token = nil)
            uri = URI.parse("#{OffsitePayments::Integrations::GoCoin.read_invoice_url_prefix}/#{item_id}")
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true
            request = Net::HTTP::Get.new(uri.path)
            request.add_field("Authorization", "Bearer #{access_token}")
            response = http.request(request)
            retrieved_params = JSON.parse(response.body.to_s)

            # Check that params in callback data and API GET Invoice data are the same (except server_time)
            params['payload'].tap { |h| h.delete 'server_time' } == retrieved_params.tap { |h| h.delete 'server_time' }
          rescue JSON::ParserError
          end

          private

          def parse(body)
            @raw = body
            @params = JSON.parse(@raw)
          rescue JSON::ParserError
          end
      end

      class Return < OffsitePayments::Return
      end
    end
  end
end
