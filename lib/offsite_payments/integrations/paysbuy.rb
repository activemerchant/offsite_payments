module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module Paysbuy
      mattr_accessor :test_url
      self.test_url = 'https://demo.paysbuy.com/paynow.aspx'

      mattr_accessor :production_url
      self.production_url = 'https://www.paysbuy.com/paynow.aspx'

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

      def self.helper(order, account, options = {})
        Helper.new(order, account, options)
      end

      def self.notification(query_string, options = {})
        Notification.new(query_string, options)
      end

      class Helper < OffsitePayments::Helper
        mapping :account, 'biz'
        mapping :amount, 'amt'
        mapping :order, 'inv'
        mapping :description, 'itm'
        mapping :notify_url, 'postURL'
      end

      class Notification < OffsitePayments::Notification
        SUCCESS = '00'
        FAIL = '99'
        PENDING = '02'

        def complete?
          status == 'Completed'
        end

        def item_id
          params['result'][2..-1]
        end

        def status
          status_code = params['result'][0..1]
          case status_code
          when SUCCESS
            'Completed'
          when FAIL
            'Failed'
          when PENDING
            'Pending'
          else
            raise "Unknown status code"
          end
        end

        def acknowledge(authcode = nil)
          true
        end
      end
    end
  end
end
