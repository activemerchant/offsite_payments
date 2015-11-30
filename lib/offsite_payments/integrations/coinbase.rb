module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module Coinbase
      mattr_accessor :service_url
      self.service_url = 'https://www.coinbase.com/checkouts/redirect'

      mattr_accessor :buttoncreate_url
      self.buttoncreate_url = 'https://api.coinbase.com/v1/buttons'

      mattr_accessor :notification_confirmation_url
      self.notification_confirmation_url = 'https://api.coinbase.com/v1/orders/%s'

      # options should be { credential1: "your API key", credential2: "your API secret" }
      def self.notification(post, options = {})
        Notification.new(post, options)
      end

      def self.return(query_string, options = {})
        Return.new(query_string, options)
      end

      class Helper < OffsitePayments::Helper
        # account should be a Coinbase API key; see https://coinbase.com/account/integrations
        # options[:credential2] should be the corresponding API secret
        def initialize(order_id, account, options)
          super

          @order = order_id
          @account = account
          @options = options
          @options[:credential1] ||= ''
          @options[:credential2] ||= ''
        end

        mapping :notify_url, 'notify_url'
        mapping :return_url, 'return_url'
        mapping :cancel_return_url, 'cancel_return_url'

        def form_fields
          uri = URI.parse(Coinbase.buttoncreate_url)

          request_body = {
            'button[auto_redirect]' => true,
            'button[name]' => @options[:description] || "Your Order",
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

          raise ActionViewHelperError, "Error occured while contacting gateway : #{json['error']}" if json['error']

          {'id' => json['button']['code']}
        rescue JSON::ParserError
          raise ActionViewHelperError, 'Invalid response from gateway. Please try again.'
        end
      end

      class Notification < OffsitePayments::Notification

        def complete?
          status == "Completed"
        end

        def item_id
          params['custom']
        end

        def transaction_id
          params['id']
        end

        def received_at
          Time.iso8601(params['created_at']).to_time.to_i
        end

        def gross
          if params['total_original'].present?
            "%.2f" % (params['total_original']['cents'].to_f / 100)
          else
            "%.2f" % (params['total_native']['cents'].to_f / 100)
          end
        end

        def currency
          params['total_native']['currency_iso']
        end

        def status
          case params['status']
          when "completed"
            "Completed"
          else
            "Failed"
          end
        end

        # Acknowledge the transaction to Coinbase. This method has to be called after a new
        # apc arrives. Coinbase will verify that all the information we received are correct
        # and will return a ok or a fail.
        def acknowledge(authcode = {})
          uri = URI.parse(Coinbase.notification_confirmation_url % transaction_id)

          response = Coinbase.do_request(uri, @options[:credential1], @options[:credential2])
          return false if response.nil?

          posted_order = @params
          parse(response)

          return false unless @params
          %w(id custom total_native status).all? { |param| posted_order[param] == @params[param] }
        end

        private

        def parse(post)
          @raw = post.to_s
          @params = JSON.parse(post)['order']
        rescue JSON::ParserError
          @params = {}
        end
      end

      class Return < OffsitePayments::Return
        def initialize(query_string, options = {})
          super
          @notification = Notification.new(@params.to_json, options)
        end

        def parse(query_string)
          parsed_hash = Rack::Utils.parse_nested_query(query_string)

          if native_cents = parsed_hash['order'] && parsed_hash['order']['total_native'] && parsed_hash['order']['total_native']['cents']
            parsed_hash['order']['total_native']['cents'] = native_cents.to_i
          end

          parsed_hash
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

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        request['ACCESS_KEY'] = api_key
        request['ACCESS_SIGNATURE'] = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), api_secret, hmac_message)
        request['ACCESS_NONCE'] = nonce.to_s

        http.request(request).body
      end
    end
  end
end
