module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module Mollie
      class API
        include ActiveUtils::PostsData

        attr_reader :token

        MOLLIE_API_V1_URI = 'https://api.mollie.nl/v1/'.freeze

        def initialize(token)
          @token = token
        end

        def get_request(resource, params = nil)
          uri = URI.parse(MOLLIE_API_V1_URI + resource)
          uri.query = params.map { |k,v| "#{CGI.escape(k)}=#{CGI.escape(v)}"}.join('&') if params
          headers = { "Authorization" => "Bearer #{token}", "Content-Type" => "application/json" }
          JSON.parse(ssl_get(uri.to_s, headers))
        end

        def post_request(resource, params = nil)
          uri = URI.parse(MOLLIE_API_V1_URI + resource)
          headers = { "Authorization" => "Bearer #{token}", "Content-Type" => "application/json" }
          data = params.nil? ? nil : JSON.dump(params)
          JSON.parse(ssl_post(uri.to_s, data, headers))
        end
      end

    end
  end
end
