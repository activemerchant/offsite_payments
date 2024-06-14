module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module SwipeGateway
      mattr_accessor :service_url
      self.service_url = 'https://swipegateway.com/en/client/payment/shopify/'

      mattr_accessor :api_url
      self.api_url = 'https://swipegateway.com'

      def self.notification(post)
        Notification.new(post)
      end

      class SwipeApi
        class SSLPoster
          include ActiveUtils::PostsData
        end
        
        def initialize(private_key, public_key)
          @private_key = private_key
          @public_key = public_key
        end

        def make_request(method, route, params = {})
          poster = SSLPoster.new

          url = SwipeGateway.api_url + route
          timestamp = Time.now.getutc.to_i

          if method == "GET"
            request_body = ''
          else
            request_body = JSON.generate(params)
          end

          authorization = [timestamp, method, route, request_body].join(' ')
          authorization = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), @private_key, authorization)
          authorization = [@public_key, timestamp, authorization].join(',')          

          headers = {'Authorization' => authorization, 'Content-Type' => 'application/json'}
          
          begin
            if method == 'GET'
              poster.ssl_get(url, headers)
            else
              poster.ssl_post(url, request_body, headers)
            end
          rescue ActiveUtils::ResponseError
            nil
          end
        end

      end

      class Helper < OffsitePayments::Helper
        mapping :amount, 'amount'
        mapping :customer, :first_name => 'first_name',
                           :last_name  => 'last_name',
                           :email      => 'email',
                           :phone      => 'phone'

        mapping :billing_address, :city     => 'city',
                                  :address1 => 'address1',
                                  :address2 => 'address2',
                                  :state    => 'state',
                                  :zip      => 'zip',
                                  :country  => 'country'

        mapping :notify_url, 'notify_url'
        mapping :return_url, 'return_url'
        mapping :cancel_return_url, 'cancel_return_url'
        
        # account must be swipe public key, :credential2 must be swipe private key
        def initialize(order_id, account, options)
          super

          @order_id = order_id
          @private_key = options[:credential2]
          @public_key = account
        end

        def form_fields
          route = '/api/v0.5/payments/'
          params = {
            :amount => @fields['amount'].to_f,
            :number => @order_id.to_s,
            :success_redirect => @fields['return_url'],
            :failure_redirect => @fields['cancel_return_url'],
            :referrer => 'Shopify OffsitePayments v1.0',
            :client => {
              :first_name => @fields['first_name'],
              :last_name => @fields['last_name'],
              :email => @fields['email'],
              :phone => @fields['phone'],
              :address => "#{@fields['address1']} #{@fields['address2']} #{@fields['state']} #{@fields['zip']},  #{@fields['country']} #{@fields['city']}"
            }
          }
          
          swipe_api = SwipeApi.new(@private_key, @public_key)
          
          data = swipe_api.make_request('POST', route, params)
          
          raise ActionViewHelperError, "Error occured while contacting gateway" if data.nil?

          parsed_response = JSON.parse(data)
          
          raise ActionViewHelperError, "Error occured while contacting gateway : #{parsed_response}" if !parsed_response['errors'].empty?

          /\/payment\/(.+)\/full_page/ =~ parsed_response['full_page_checkout']
          
          {
            'hash' => $1,
            'notify_url' => @fields['notify_url']
          }
        rescue JSON::ParserError
          raise ActionViewHelperError, 'Invalid response from gateway. Please try again.'
        end    
      end

      class Notification < OffsitePayments::Notification
        def complete?
          params['status'] == 'paid'
        end

        def item_id
          params['number'].to_s
        end

        def transaction_id
          params['id'].to_s
        end

        # When was this payment received by the client.
        def received_at
          Time.iso8601(params['paid_on']).to_time.to_i
        end

        def payer_email
          params['client']['email']
        end

        # Defined in Swipe merchant's for all payments
        def currency
          params['currency']['code']
        end

        # the money amount we received in X.2 decimal.
        def gross
         "%.2f" % params['amount']
        end

        # Was this a test transaction?
        def test?
          params['is_test']
        end

        def status
          params['status'] == 'paid' ? 'Complete' : 'Failed'
        end
        
        # credential1 must be swipe public key, # credential2 must swipe private key
        def acknowledge(authcode = {})
          swipe_api = SwipeApi.new(@options[:credential2], @options[:credential1])
          response = swipe_api.make_request('GET', '/api/v0.5/payments/%s/' % transaction_id)

          return false if response.nil?

          posted_order = @params
          parse(response)

          return false if @params.empty?
          return false if !%w(id status number).all? { |param| posted_order[param] == @params[param] }          
          return false if @params['status'] != 'paid'          
          return false if @params['errors'] && !@params['errors'].empty?
          
          true
        end

        private

        def parse(post)
          @raw = post.to_s
          @params = JSON.parse(post)
        rescue JSON::ParserError
          @params = {}
        end
      end

      class Return < OffsitePayments::Return
      end

    end
  end
end
