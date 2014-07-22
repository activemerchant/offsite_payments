module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module MercadoPago

      mattr_accessor :oauth_url
      self.oauth_url = 'https://api.mercadolibre.com/oauth/token'

      mattr_accessor :service_url
      self.service_url = "https://www.mercadopago.com/checkout/form"

      def self.test?
        OffsitePayments.mode == :test
      end

      def self.notification(post)
        Notification.new(post)
      end

      class Helper < OffsitePayments::Helper
        # MP Preference
        def initialize(order, account, options)
          super
          @client_id = account
          @client_secret = options[:credential2]
          @test = OffsitePayments.mode == :test

          #item
          add_field('item_unit_price', sprintf("%0.02f", options[:amount]))
          add_field('item_quantity', '1')
        end

        mapping :account, 'client_id'
        mapping :credential2, 'client_secret'

        mapping :order, 'external_reference'

        #item
        mapping :description, 'item_title'

        # back_url
        mapping :notify_url, 'notification_url'
        mapping :return_url, 'success_url'
        mapping :cancel_return_url, 'failure_url'

        mapping :billing_address,   :address1 => 'payer_street_name' ,
                                    :zip => 'payer_zip_code'

        mapping :customer,  :first_name => 'payer_name' ,
                            :last_name => 'payer_surname' ,
                            :email => 'payer_email',
                            :phone => 'phone_number'

        def form_fields
          {
            "test" => @test ,
            "access_token" => get_access_token(@client_id, @client_secret)
          }
        end

        def get_access_token(client_id, client_secret)
          uri = URI.parse(MercadoPago.oauth_url)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true

          request = Net::HTTP::Post.new(uri)
          request.content_type = "application/x-www-form-urlencoded"
          payload = {
            "grant_type" => "client_credentials",
            "client_id" => client_id.to_s,
            "client_secret" => client_secret.to_s
          }

          request.set_form_data(payload)

          response = http.request(request)
          json = JSON.parse(response.body)

          if response.code == "200"
            return json["access_token"]
          else
            raise ActiveMerchant::ResponseError, response
          end

          rescue Timeout::Error, Errno::ECONNRESET, Errno::ETIMEDOUT => e
            raise ActionViewHelperError, "Connection Error"
        end

      end

      class Notification < OffsitePayments::Notification

        def initialize(post)
          @params = parse_ipn(post)
        end

        def parse_ipn(json)
          JSON.parse(json.to_s)
        end

        def complete?
          params["status"] == "approved"
        end

        def item_id
          params['order_id']
        end

        def transaction_id
          params['id']
        end

        def payer_email
          return if params['payer'].nil?
          params['payer']['email']
        end

        def receiver_email
          return if params['collector'].nil?
          params['collector']['email']
        end

        def currency
          params['currency_id']
        end

        # When was this payment received by the client.
        def received_at
          params['date_created']
        end

        def payer_email
          params['payer']['email']
        end

        def gross
          params['total_paid_amount']
        end

        def status
          case params["status"]
          when "approved"
            "Completed"
          when "pending"
            "Pending"
          when "rejected"
            "Failed"
          end
        end

        def test
          false
        end

        def acknowledge(authcode = nil)
          reuturn true
        end

        private

        def parse_http_query(post)
          @raw = post
          params = {}
          for line in post.split('&')
            key, value = *line.scan( %r{^(\w+)\=(.*)$} ).flatten
            params[key] = value
          end
          params
        end

      end
    end
  end
end
