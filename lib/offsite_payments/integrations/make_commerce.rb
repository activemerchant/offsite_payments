
module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module MakeCommerce

      def self.service_url
        case OffsitePayments.mode
        when :production
          'https://payment.maksekeskus.ee/pay/1/link.html'
        when :test
          'https://payment-test.maksekeskus.ee/pay/1/link.html'
        else
          raise StandardError, "Integration mode set to an invalid value: #{mode}"
        end
      end
      
      def self.notification(post)
        Notification.new(post)
      end

      class Helper < OffsitePayments::Helper

        mapping :amount, 'amount'
        mapping :order, 'reference'

        mapping :notify_url, 'notification_url'
        mapping :return_url, 'return_url'
        mapping :cancel_url, 'cancel_url'
        
        mapping :credential2, 'shop'

      end

      class Notification < OffsitePayments::Notification
        def complete?
          params[:type] == 'return' && params[:json]['status'] == 'COMPLETED'
        end

        def item_id
          params[:json]['reference']
        end

        def transaction_id
          params[:json]['transaction']
        end

        # When was this payment received by the client.
        def received_at
          params[:json]['message_time']
        end

        def payer_name
          params[:json]['customer_name']
        end

        def security_key
          params[:mac]
        end
        
        def gross
          params[:json]['amount']
        end

        def currency
          params[:json]['currency']
        end

        def test?
          false
        end

        def status
          case params[:json]['status']
          when "PAID", "COMPLETED"
            "completed"
          when "CANCELLED", "EXPIRED", "PART_REFUNDED", "REFUNDED", "DECLINED"
            "failed"
          else
            "pending"
          end
        end

        def acknowledge(authcode = nil)
          return params[:mac] == Digest::SHA2.new(512).hexdigest(params[:rawjson]+authcode).upcase
        end

        private

        def parse(post)
          post.each do |key, value|
            if key == :json
              params[:rawjson] = value
              value = JSON.parse(value)
            end
            params[key] = value
          end
        end
      end
    end
  end
end
