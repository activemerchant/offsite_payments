module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module Coinbase

      mattr_accessor :service_url
      self.service_url = 'https://coinbase.com/checkouts/redirect'

      mattr_accessor :buttoncreate_url
      self.buttoncreate_url = 'https://coinbase.com/api/v1/buttons'

      mattr_accessor :notification_confirmation_url
      self.notification_confirmation_url = 'https://coinbase.com/api/v1/orders/%s'

      def self.notification(post)
        Notification.new(post)
      end

      def self.return(query_string, options = {})
        Return.new(query_string)
      end

      class Helper < OffsitePayments::Helper
        # account should be a Coinbase API key; see https://coinbase.com/account/integrations
        # options[:credential2] should be the corresponding API secret
        def initialize(order_id, account, options)
          super

          @order = order_id
          @account = account
          @options = options
        end

        mapping :notify_url, 'notify_url'
        mapping :return_url, 'return_url'
        mapping :cancel_return_url, 'cancel_return_url'

        def form_fields
          uri = URI.parse(Coinbase.buttoncreate_url)

          title = @options[:description]
          if title.nil?
            title = "Your Order"
          end

          request_body = {
            'button[name]' => title,
            'button[price_string]' => @options[:amount],
            'button[price_currency_iso]' => @options[:currency],
            'button[custom]' => @order,
            'button[callback_url]' => @fields['notify_url'],
            'button[success_url]' => @fields['return_url'],
            'button[cancel_url]' => @fields['cancel_return_url'],
            'api_key' => @account
          }.to_query

          data = Coinbase.do_request(uri, @account, @options[:credential2], request_body)
          json = JSON.parse(data)

          if json.nil?
            raise "Response invalid %s" % data
          end
          unless json['success']
            raise "JSON error %s" % JSON.pretty_generate(json)
          end

          button = json['button']

          {'id' => button['code']}
        end
      end

      class Notification < OffsitePayments::Notification
        def complete?
          status == "completed"
        end

        def item_id
          params['custom']
        end

        def transaction_id
          params['id']
        end

        # When was this payment received by the client.
        def received_at
          Time.iso8601(params['created_at']).to_time.to_i
        end

        # the money amount we received in X.2 decimal.
        def gross
          params['total_native']['cents'].to_f / 100
        end

        def currency
          params['total_native']['currency_iso']
        end

        # Was this a test transaction?
        def test?
          false
        end

        def status
          params['status']
        end

        # Acknowledge the transaction to Coinbase. This method has to be called after a new
        # apc arrives. Coinbase will verify that all the information we received are correct and will return a
        # ok or a fail.
        #
        # authcode should be { api_key: "your API key", api_secret: "your API secret" }
        #
        # Example:
        #
        #   def ipn
        #     notify = CoinbaseNotification.new(request.raw_post)
        #
        #     if notify.acknowledge({ api_key: "your API key", api_secret: "your API secret" })
        #       ... process order ... if notify.complete?
        #     else
        #       ... log possible hacking attempt ...
        #     end
        def acknowledge(authcode = {})

          uri = URI.parse(Coinbase.notification_confirmation_url % transaction_id)

          response = Coinbase.do_request(uri, authcode[:api_key], authcode[:api_secret])
          order = JSON.parse(response)

          if order.nil?
            return false
          end

          order = order['order']

          # check all properties with the server
          order['custom'] == @params['custom'] && order['created_at'] == @params['created_at'] && order['total_native'] == @params['total_native'] && order['status'] == @params['status']
        end

        private

        # Take the posted data and move the relevant data into a hash
        def parse(post)
          @params = post['order']
        end
      end

      protected

      def self.do_request(uri, api_key, api_secret, post_body = nil)

        nonce = (Time.now.to_f * 1e6).to_i
        hmac_message = nonce.to_s + uri.to_s

        if post_body
          request = Net::HTTP::Post.new(uri.request_uri)
          request.body = post_body
          hmac_message = hmac_message + request.body
        else
          request = Net::HTTP::Get.new(uri.path)
        end

        puts "going to #{uri.path} #{uri.host} #{uri.port}"

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        # Authentication
        request['ACCESS_KEY'] = api_key
        request['ACCESS_SIGNATURE'] = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), api_secret, hmac_message)
        request['ACCESS_NONCE'] = nonce.to_s

        http.request(request).body
      end
    end
  end
end
