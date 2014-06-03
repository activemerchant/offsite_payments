module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module Bogus
      mattr_accessor :service_url
      self.service_url = 'http://www.bogus.com'

      def self.notification(post, options = {})
        Notification.new(post)
      end

      def self.return(query_string, options = {})
        Return.new(query_string)
      end

      class Helper < OffsitePayments::Helper
        mapping :account, 'account'
        mapping :order, 'order'
        mapping :amount, 'amount'
        mapping :currency, 'currency'
        mapping :customer, :first_name => 'first_name',
                           :last_name => 'last_name'

      end

      class Notification < OffsitePayments::Notification
      end

      class Return < OffsitePayments::Return
      end
    end
  end
end
