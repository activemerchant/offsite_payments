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
        mapping :credential3, "sph-account-key"
        mapping :credential4, "sph-account-secret"
        mapping :success_url, "sph-success-url"
        mapping :failure_url, "sph-failure-url"
        mapping :cancel_url, "sph-cancel-url"

        def form_fields
          @fields.merge("signature" => generate_signature)
        end

        def generate_signature
          contents = ["POST"]
          contents << "/form/view/pay_with_card"
          contents << "sph-account=#{@fields["sph-account"]}"
          contents << "sph-merchant=#{@fields["sph-merchant"]}"
          contents << "sph-order=#{@fields["sph-order"]}"
          contents << "sph-request-id=#{@fields["sph-request-id"]}"
          contents << "sph-amount=#{@fields["sph-amount"]}"
          contents << "sph-currency=#{@fields["sph-currency"]}"
          contents << "sph-timestamp=#{@fields["sph-timestamp"]}"
          contents << "sph-success-url=#{@fields["sph-success-url"]}"
          contents << "sph-failure-url=#{@fields["sph-failure-url"]}"
          contents << "sph-cancel-url=#{@fields["sph-cancel-url"]}"
          contents << "language=#{@fields['language']}"
          contents << "description=#{@fields['description']}"
          OpenSSL::HMAC.hexdigest('sha256', account_secret, contents.join("\n"))
        end

        private def generate_request_id
          SecureRandom.uuid
        end

        private def account_secret
          @fields['sph-account-secret']
        end
      end
    end
  end
end
