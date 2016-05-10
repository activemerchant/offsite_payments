require 'offsite_payments/integrations/payment_highway/helper'
require 'offsite_payments/integrations/payment_highway/notification'

module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module PaymentHighway
      mattr_accessor :service_url
      self.service_url = 'https://www.example.com'

      def self.notification(post)
        Notification.new(post)
      end
    end
  end
end
