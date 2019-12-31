module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module Mollie
      class API
        include ActiveUtils::NetworkConnectionRetries
        include ActiveUtils::PostsData

        attr_reader :token

        MOLLIE_API_V1_URI = 'https://api.mollie.nl/v1/'.freeze

        def initialize(token)
          @token = token
        end

        def get_request(resource, params = nil)
          retry_exceptions({retry_safe: true}) do
            uri = URI.parse(MOLLIE_API_V1_URI + resource)
            uri.query = params.map { |k,v| "#{CGI.escape(k)}=#{CGI.escape(v)}"}.join('&') if params
            headers = { "Authorization" => "Bearer #{token}", "Content-Type" => "application/json" }
            JSON.parse(ssl_get(uri.to_s, headers))
          end
        end

        def post_request(resource, params = nil)
          uri = URI.parse(MOLLIE_API_V1_URI + resource)
          headers = { "Authorization" => "Bearer #{token}", "Content-Type" => "application/json" }
          data = params.nil? ? nil : JSON.dump(params)
          JSON.parse(ssl_post(uri.to_s, data, headers))
        end
      end

      class Helper < OffsitePayments::Helper
        def credential_based_url
          response = request_redirect
          @transaction_id = response['id']

          uri = URI.parse(response['links']['paymentUrl'])
          set_form_fields_for_redirect(uri)
          uri.query = ''
          uri.to_s.sub(/\?\z/, '')
        end

        def form_method
          "GET"
        end

        private

        def set_form_fields_for_redirect(uri)
          return unless uri.query

          CGI.parse(uri.query).each do |key, value|
            if value.is_a?(Array) && value.length == 1
              add_field(key, value.first)
            else
              add_field(key, value)
            end
          end
        end
      end
    end
  end
end
