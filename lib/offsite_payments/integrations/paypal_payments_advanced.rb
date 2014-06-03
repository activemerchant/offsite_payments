module OffsitePayments
  module Integrations
    module PaypalPaymentsAdvanced
      mattr_accessor :service_url
      self.service_url = 'https://payflowlink.paypal.com'

      def self.notification(post, options = {})
        PayflowLink::Notification.new(post)
      end

      def self.return(query_string, options = {})
        Return.new(query_string)
      end

      class Helper < PayflowLink::Helper
        def initialize(order, account, options)
          super
          add_field('partner', 'PayPal')
        end
      end
    end
  end
end
