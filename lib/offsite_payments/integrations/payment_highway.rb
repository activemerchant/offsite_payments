require 'offsite_payments/integrations/payment_highway/helper'

module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module PaymentHighway
      mattr_accessor :test_url
      self.test_url = "https://v1-hub-staging.sph-test-solinor.com/form/view/pay_with_card"

      mattr_accessor :production_url
      self.production_url = "https://v1.api.paymenthighway.io/form/view/pay_with_card"

      def self.service_url
        mode = OffsitePayments.mode
        case mode
        when :production
          self.production_url
        when :test
          self.test_url
        else
          raise StandardError, "Integration mode set to an invalid value: #{mode}"
        end
      end

      def self.notification(post)
        Notification.new(post)
      end
    end
  end
end
