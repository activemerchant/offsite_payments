module OffsitePayments
  module Integrations
    module PayuInPaisa
      mattr_accessor :test_url
      mattr_accessor :production_url

      self.test_url = 'https://test.payu.in/_payment.php'
      self.production_url = 'https://secure.payu.in/_payment.php'

      def self.service_url
        OffsitePayments.mode == :production ? self.production_url : self.test_url
      end

      def self.notification(post, options = {})
        Notification.new(post, options)
      end

      def self.return(post, options = {})
        Return.new(post, options)
      end

      class Helper < PayuIn::Helper
        mapping :service_provider, 'service_provider'

        def initialize(order, account, options = {})
          super
          self.service_provider = 'payu_paisa'
          self.user_defined = { :var2 => order }
        end
      end

      class Notification < PayuIn::Notification
        def item_id
          params['udf2']
        end
      end

      class Return < PayuIn::Return
        def initialize(query_string, options = {})
          super
          @notification = Notification.new(query_string, options)
        end
      end
    end
  end
end
