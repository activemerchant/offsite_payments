require 'openssl'

module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module QuickpayV10
      mattr_accessor :service_url
      self.service_url = 'https://payment.quickpay.net'

      def self.notification(post, options = {})
        Notification.new(post)
      end

      def self.return(post, options = {})
        Return.new(post, options)
      end

      # credential2: Payment window API key
      class Helper < OffsitePayments::Helper
        def initialize(order, account, options = {})
          payment_window_api_key options.delete(:credential2)
          super
          add_field('version', 'v10')
          add_field('type', 'payment')
          add_field('language', 'da')
          add_field('autocapture', 0)
          add_field('order_id', format_order_number(order))
        end

        def payment_window_api_key(value)
          @payment_window_api_key = value
        end

        def form_fields
          @fields.merge('checksum' => generate_checksum)
        end
        
        def flatten_params(obj, result = {}, path = [])
          case obj
          when Hash
            obj.each do |k, v|
              flatten_params(v, result, [*path, k])
            end
          when Array
            obj.each_with_index do |v, i|
              flatten_params(v, result, [*path, i])
            end
          else
            result[path.map{|p| "[#{p}]"}.join.to_sym] = obj
          end
          result
        end

        def generate_checksum
          flattened_params = flatten_params(@fields)
          values = flattened_params.sort.map { |_, value| value }
          base = values.join(' ')
          OpenSSL::HMAC.hexdigest('sha256', @payment_window_api_key, base)
        end

        # Limited to 20 digits max
        def format_order_number(number)
          number.to_s.gsub(/[^\w]/, '').rjust(4, "0")[0...20]
        end

        mapping :version, 'version'
        mapping :type, 'type'
        mapping :account, 'merchant_id'
        mapping :language, 'language'
        mapping :amount, 'amount'
        mapping :currency, 'currency'

        mapping :return_url, 'continueurl'
        mapping :cancel_return_url, 'cancelurl'
        mapping :notify_url, 'callbackurl'

        mapping :autocapture, 'autocapture'
        mapping :autofee, 'autofee'

        mapping :description, 'description'
        mapping :payment_methods, 'payment_methods'
        mapping :acquirer, 'acquirer'
        mapping :branding_id, 'branding_id'
        mapping :google_analytics_tracking_id, 'google_analytics_tracking_id'
        mapping :google_analytics_client_id, 'google_analytics_client_id'
        mapping :variables, 'variables'
        mapping :text_on_statement, 'text_on_statement'
        mapping :customer_email, 'customer_email'

        mapping :splitpayment, 'splitpayment'
        mapping :forcemobile, 'forcemobile'
        mapping :deadline, 'deadline'
        mapping :cardhash, 'cardhash'

        mapping :invoice_address, {}
        mapping :billing_address, {}
      end
      
      # credential3: private key
      # checksum_header: QuickPay-Checksum-Sha256 request header value
      class Notification < OffsitePayments::Notification
        # http://tech.quickpay.net/appendixes/errors/
        def complete?
          status == '20000'
        end

        def item_id
          params['order_id']
        end

        def transaction_id
          params['id']
        end

        def received_at
          Time.iso8601(params['created_at'])
        end

        def gross
          "%.2f" % (gross_cents / 100.0)
        end

        def gross_cents
          last_operation['amount']
        end
        
        def last_operation
          params['operations'].last
        end

        def status
          last_operation['qp_status_code'] if last_operation
        end

        # Provide access to raw fields from quickpay
        %w(
          accepted
          test_mode
          branding_id
          variables
          acquirer
          operations
          metadata
          balance
          currency
        ).each do |attr|
          define_method(attr) do
            params[attr]
          end
        end
        
        def generate_checksum
          OpenSSL::HMAC.hexdigest('sha256', @options[:credential3], @raw)
        end
        
        def checksum_header
          @options[:checksum_header]
        end

        # Quickpay doesn't do acknowledgements of callback notifications
        # Instead it provides a SHA256 checksum header
        def acknowledge(authcode = nil)
          generate_checksum == checksum_header
        end

        # Take the posted data and move the relevant data into a hash
        def parse(post)
          @raw = post.to_s
          @params = JSON.parse(post)
        end
      end
    end
  end
end
