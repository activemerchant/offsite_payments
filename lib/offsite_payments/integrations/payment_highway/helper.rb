module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module PaymentHighway
      class Helper < OffsitePayments::Helper
        def initialize(order, merchantnumber, options = {})
          super
          add_field("sph-merchant", merchantnumber)
          add_field("sph-request-id", generate_request_id)
          add_field("sph-currency", options.fetch(:currency))
          add_field("sph-timestamp", Time.now.utc.xmlschema)
          @account_key = options.fetch(:credential3)
          @secret = options.fetch(:credential4)
        end
        # Replace with the real mapping
        mapping :account, "sph-account"
        mapping :amount, "sph-amount"

        mapping :order, 'sph-order'

        mapping :customer, :first_name => '',
          :last_name  => '',
          :email      => '',
          :phone      => ''

        mapping :billing_address, :city     => '',
          :address1 => '',
          :address2 => '',
          :state    => '',
          :zip      => '',
          :country  => ''

        mapping :description, 'description'
        mapping :tax, ''
        mapping :shipping, ''
        mapping :language, "language"

        mapping :credential2, "sph-account"
        mapping :success_url, "sph-success-url"
        mapping :failure_url, "sph-failure-url"
        mapping :cancel_url, "sph-cancel-url"

        def form_fields
          @fields.merge("signature" => generate_signature)
        end

        def generate_signature
          contents = ["POST", "/form/view/pay_with_card", self.class.select_and_format_params(@fields), ""]

          "SPH1 #{@account_key} #{OpenSSL::HMAC.hexdigest('sha256', @secret, contents.flatten.join("\n"))}"
        end

        def self.valid_signature?(account_key, secret, params)
          contents = ["GET", "", select_and_format_params(params), ""]

          params["signature"] ==  "SPH1 #{account_key} #{OpenSSL::HMAC.hexdigest('sha256', secret, contents.flatten.join("\n"))}"
        end

        private

        def generate_request_id
          SecureRandom.uuid
        end

        def self.select_and_format_params params
          params.select{ |k,v|
            k.to_s.match(/^sph-/i)
          }.sort.map{ |k,v|
            "#{k.downcase}:#{v}"
          }
        end
      end
    end
  end
end
