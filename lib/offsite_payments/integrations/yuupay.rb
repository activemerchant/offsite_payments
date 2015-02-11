module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module Yuupay 
      include Universal

      def self.notification(post, options = {})
        Notification.new(post, options)
      end

      def self.return(query_string, options = {})
        Return.new(query_string, options)
      end

      def self.sign(fields, key)
        OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA256.new, key, fields.sort.join)
      end

      class Helper < Universal::Helper
        def forward_url 
          'https://checkout.yuupay.net/payment/index.php'
        end
      end
    end
  end
end
