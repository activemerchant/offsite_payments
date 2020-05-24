module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module BitPay
      API_V1_URL = 'https://bitpay.com/api/invoice'
      API_V2_TOKEN_REGEX = /^[^0OIl]{44,}$/
      API_V2_URL = 'https://bitpay.com/invoices'

      mattr_accessor :service_url
      self.service_url = 'https://bitpay.com/invoice'

      def self.notification(post, options = {})
        Notification.new(post, options)
      end

      def self.helper(order, account, options = {})
        Helper.new(order, account, options)
      end

      def self.return(query_string, options = {})
        Return.new(query_string)
      end

      def self.v2_api_token?(api_token)
        API_V2_TOKEN_REGEX.match(api_token)
      end

      def self.invoicing_url(api_token)
        if v2_api_token?(api_token)
          API_V2_URL
        else
          API_V1_URL
        end
      end

      class Helper < OffsitePayments::Helper
        def initialize(order_id, account, options)
          super
          @account = account

          add_field('posData', {'orderId' => order_id}.to_json)
          add_field('fullNotifications', true)
          add_field('transactionSpeed', 'high')
          add_field('token', account)
        end

        mapping :amount, 'price'
        mapping :order, 'orderID'
        mapping :currency, 'currency'

        mapping :customer, :first_name => 'buyerName',
                           :email      => 'buyerEmail',
                           :phone      => 'buyerPhone'

        mapping :billing_address, :city     => 'buyerCity',
                                  :address1 => 'buyerAddress1',
                                  :address2 => 'buyerAddress2',
                                  :state    => 'buyerState',
                                  :zip      => 'buyerZip',
                                  :country  => 'buyerCountry'

        mapping :notify_url, 'notificationURL'
        mapping :return_url, 'redirectURL'
        mapping :id, 'id'

        def form_method
          "GET"
        end

        def form_fields
          invoice = create_invoice

          raise ActionViewHelperError, "Invalid response while retrieving BitPay Invoice ID. Please try again." unless invoice

          { "id" => extract_invoice_id(invoice) }
        end
        private

        def add_plugin_info(request)
          #add plugin info for v1 and v2 tokens
          if BitPay.v2_api_token?(@account)
            request.add_field("x-bitpay-plugin-info", "BitPay_AM" + application_id + "_Client_v2.0.1909")
          else
            request.add_field("x-bitpay-plugin-info", "BitPay_AM" + application_id + "_Client_v1.0.1909")
            request.basic_auth @account, ''
          end
        end

        def create_invoice
          uri = URI.parse(BitPay.invoicing_url(@account))
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true

          request = Net::HTTP::Post.new(uri.request_uri)
          request.content_type = "application/json"
          request.body = @fields.to_json
          add_plugin_info(request)

          response = http.request(request)
          JSON.parse(response.body)
        end

        def extract_invoice_id(invoice)
          if BitPay.v2_api_token?(@account)
            invoice['data']['id']
          else
            invoice['id']
          end
        end
      end

      class Notification < OffsitePayments::Notification
        def complete?
          status == "Completed"
        end

        def transaction_id
          params['id']
        end

        def item_id
          JSON.parse(params['posData'])['orderId']
        end

        def status
          case params['status']
          when 'complete'
            'Completed'
          when 'confirmed'
            'Pending'
          when 'invalid'
            'Failed'
          end
        end

        # When was this payment received by the client.
        def received_at
          params['invoiceTime'].to_i
        end

        def currency
          params['currency']
        end

        def gross
          params['price'].to_f
        end

        def acknowledge(authcode = nil)
          uri = URI.parse("#{OffsitePayments::Integrations::BitPay::API_V2_URL}/#{transaction_id}")

          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true

          request = Net::HTTP::Get.new(uri.path)
          response = http.request(request)

          received_attributes = [transaction_id, status]

          parse(response.body)

          received_attributes == [transaction_id, status]
        end

        private
        def parse(body)
          @raw = body
          json = JSON.parse(@raw)

          @params = json.key?('data') ? json['data'] : json
        end
      end

      class Return < OffsitePayments::Return
      end
    end
  end
end
