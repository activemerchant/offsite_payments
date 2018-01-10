module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module BitPay
      mattr_accessor :service_url
      self.service_url = 'https://bitpay.com/invoice'

      mattr_accessor :invoicing_url
      self.invoicing_url = 'https://bitpay.com/api/invoice'

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
        def initialize(order_id, account, options)
          super
          @account = account

          add_field('posData', {'orderId' => order_id}.to_json)
          add_field('fullNotifications', true)
          add_field('transactionSpeed', 'high')
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

          {"id" => invoice['id']}
        end

        private

        def create_invoice
          uri = URI.parse(BitPay.invoicing_url)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true

          request = Net::HTTP::Post.new(uri.request_uri)
          request.content_type = "application/json"
          request.body = @fields.to_json
          request.basic_auth @account, ''

          response = http.request(request)
          JSON.parse(response.body)
        rescue JSON::ParserError
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
          uri = URI.parse("#{OffsitePayments::Integrations::BitPay.invoicing_url}/#{transaction_id}")

          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true

          request = Net::HTTP::Get.new(uri.path)
          request.basic_auth @options[:credential1], ''

          response = http.request(request)

          posted_json = JSON.parse(@raw).tap { |j| j.delete('currentTime') }
          parse(response.body)
          retrieved_json = JSON.parse(@raw).tap { |j| j.delete('currentTime') }

          posted_json == retrieved_json
        end

        private
        def parse(body)
          @raw = body
          @params = JSON.parse(@raw)
        end
      end

      class Return < OffsitePayments::Return
      end
    end
  end
end
