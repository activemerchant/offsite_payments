module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module CheckoutFinland

      mattr_accessor :service_url
      self.service_url = 'https://payment.checkout.fi/'

      def self.notification(post)
        Notification.new(post)
      end

      class Helper < OffsitePayments::Helper
        include ActiveUtils::PostsData
        self.country_format = :alpha3

        def initialize(order, account, options = {})
          md5secret options.delete(:credential2)
          super

          # Add default fields
          add_field("VERSION", "0001") # API version
          add_field("ALGORITHM", "3") # Return MAC version (3 is HMAC-SHA256)
          add_field("TYPE", "0")
          add_field("DEVICE", "1") # Offsite payment by default
        end

        def md5secret(value)
          @md5secret = value
        end

        # Add MAC to form fields
        def form_fields
          @fields.merge("MAC" => generate_md5string)
        end

        # Apply parameter length limitations recommended by Checkout.fi
        def add_field(name, value)
          return if name.blank? || value.blank?
          @fields[name.to_s] = check_param_length(name_to_s, value.to_s)
        end

        # API parameter length limitations specified by Checkout.fi
        # Parameters longer than this cause the HTTP POST to fail
        def check_param_length(name, value)
          # Soft limitations, fields that can be clipped
          max_length_substring = { "FIRSTNAME" => 40, "FAMILYNAME" => 40, "ADDRESS" => 40, "POSTCODE" => 14, "POSTOFFICE" => 18, "MESSAGE" => 1000, "EMAIL" => 200, "PHONE" => 30 }
          # Hard limitations, fields that cannot be clipped
          max_length_exception = { "RETURN" => 300, "CANCEL" => 300, "REJECT" => 300, "DELAYED" => 300, "STAMP" => 20, "AMOUNT" => 8, "REFERENCE" => 20, "CONTENT" => 2, "LANGUAGE" => 2, "MERCHANT" => 20, "COUNTRY" => 3, "CURRENCY" => 3, "DELIVERY_DATE" => 8 }
          if max_length_substring.include? name
            return value.to_s[0, max_length_substring[name]]
          end
          if max_length_exception.include? name
            if value.to_s.length > max_length_exception[name]
              raise ArgumentError, "Field #{name} length #{value.length} is longer than permitted by provider API. Maximum length #{max_length_exception[name]}."
            else
              return value
            end
          end
          value
        end

        # Calculate MAC
        def generate_md5string
          fields = [@fields["VERSION"], @fields["STAMP"], @fields["AMOUNT"], @fields["REFERENCE"],
                    @fields["MESSAGE"], @fields["LANGUAGE"], @fields["MERCHANT"], @fields["RETURN"],
                    @fields["CANCEL"], @fields["REJECT"], @fields["DELAYED"], @fields["COUNTRY"],
                    @fields["CURRENCY"], @fields["DEVICE"], @fields["CONTENT"], @fields["TYPE"],
                    @fields["ALGORITHM"], @fields["DELIVERY_DATE"], @fields["FIRSTNAME"], @fields["FAMILYNAME"],
                    @fields["ADDRESS"], @fields["POSTCODE"], @fields["POSTOFFICE"], @md5secret]
           fields = fields.join("+")
           Digest::MD5.hexdigest(fields).upcase 
        end

        # Mappings
        mapping :order, 'STAMP' # Unique order number for each payment
        mapping :account, 'MERCHANT' # Checkout Merchant ID
        mapping :amount, 'AMOUNT' # Amount in cents
        mapping :reference, 'REFERENCE' # Reference for bank statement
        mapping :language, 'LANGUAGE' # "FI" / "SE" / "EN"
        mapping :currency, 'CURRENCY' # "EUR" currently only
        mapping :device, 'DEVICE' # "1" = HTML / "10" = XML
        mapping :content, 'CONTENT' # "1" = NORMAL "2" = ADULT CONTENT
        mapping :delivery_date, 'DELIVERY_DATE' # "YYYYMMDD"
        mapping :description, 'MESSAGE' # Description of the order

        # Optional customer data supported by API (not mandatory)
        mapping :customer, :first_name => 'FIRSTNAME',
                           :last_name  => 'FAMILYNAME',
                           :email      => 'EMAIL',
                           :phone      => 'PHONE'

        # Optional fields supported by API (not mandatory)
        mapping :billing_address, :city     => 'POSTOFFICE',
                                  :address1 => 'ADDRESS',
                                  :zip      => 'POSTCODE',
                                  :country  => 'COUNTRY'

        mapping :notify_url, 'DELAYED' # Delayed payment URL (mandatory)
        mapping :reject_url, 'REJECT' # Rejected payment URL (mandatory)
        mapping :return_url, 'RETURN' # Payment URL (optional)
        mapping :cancel_return_url, 'CANCEL' # Cancelled payment URL (optional)
      end

      class Notification < OffsitePayments::Notification
        # Payment can be market complete with the following status codes
        def complete?
          ["2", "5", "6", "8", "9", "10"].include? params["STATUS"]
        end

        # Did the customer choose delayed payment method
        def delayed?
          params['STATUS'] == "3"
        end

        # Did the customer cancel the payment
        def cancelled?
          params['STATUS'] == "-1"
        end

        # Payment requires manual activation (fraud check etc)
        def activation?
          params['STATUS'] == "7"
        end

        # Reference specified by the client when sending payment
        def reference
          params['REFERENCE']
        end

        # Unique ID assigned by Checkout
        def transaction_id
          params['PAYMENT']
        end

        # Unique ID assigned by customer
        def stamp
          params['STAMP']
        end

        # Returned Message Authentication Code
        def mac
          params['MAC']
        end

        def status
          params['STATUS']
        end

        # Verify authenticity of returned data
        def acknowledge(authcode = nil)
          return_authcode = [params["VERSION"], params["STAMP"], params["REFERENCE"], params["PAYMENT"], params["STATUS"], params["ALGORITHM"]].join("&")
          OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), authcode, return_authcode).upcase == params["MAC"]
        end

        private

        # Take the posted data and move the data into params
        def parse(post)
          post.each do |key, value|
            params[key] = value
          end
        end
      end
    end
  end
end
