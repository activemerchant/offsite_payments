module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module Paydollar
      CURRENCY_MAP = {
          'AED' => '784',
          'AUD' => '036',
          'BND' => '096',
          'CAD' => '124',
          'CNY' => '156',
          'EUR' => '978',
          'GBP' => '826',
          'HKD' => '344',
          'IDR' => '360',
          'JPY' => '392',
          'KRW' => '410',
          'MOP' => '446',
          'MYR' => '458',
          'NZD' => '554',
          'PHP' => '608',
          'SAR' => '682',
          'SGD' => '702',
          'THB' => '764',
          'TWD' => '901',
          'USD' => '840',
      }

      def self.service_url
        case OffsitePayments.mode
        when :production
          'https://www.paydollar.com/b2c2/eng/payment/payForm.jsp'
        when :test
          'https://test.paydollar.com/b2cDemo/eng/payment/payForm.jsp'
        else
          raise StandardError, "Integration mode set to an invalid value: #{mode}"
        end
      end

      def self.notification(post, options = {})
        Notification.new(post, options)
      end

      def self.return(query_string, options = {})
        Return.new(query_string, options)
      end

      def self.sign(fields, secret)
        Digest::SHA1.hexdigest(fields.push(secret).join('|'))
      end

      class Helper < OffsitePayments::Helper
        def initialize(order, account, options = {})
          super
          add_field('payType', 'N') # normal sale and not just auth
          @secret = options[:credential2]
        end

        def form_fields
          @fields.merge('secureHash' => generate_secure_hash)
        end

        def generate_secure_hash
          fields = [@fields[mappings[:account]],
                    @fields[mappings[:order]],
                    @fields[mappings[:currency]],
                    @fields[mappings[:amount]],
                    @fields['payType']]
          Paydollar.sign(fields, @secret)
        end

        def currency=(currency_code)
          add_field(mappings[:currency], CURRENCY_MAP[currency_code])
        end

        mapping :account, 'merchantId'
        mapping :amount, 'amount'
        mapping :order, 'orderRef'
        mapping :currency, 'currCode'
        mapping :return_url, 'successUrl'
        mapping :cancel_return_url, ['cancelUrl','failUrl']
      end

      class Notification < OffsitePayments::Notification
        def complete?
          status == 'Completed'
        end

        def item_id
          @params['Ref']
        end

        def currency
          CURRENCY_MAP.key(@params['Cur'])
        end

        def gross
          @params['Amt']
        end

        def transaction_id
          @params['PayRef']
        end

        def status
          case @params['successcode']
            when '0' then 'Completed'
            else 'Failed'
          end
        end

        def acknowledge(authcode = nil)
          # paydollar supports multiple signature keys, therefore we need to check if any
          # of their signatures match ours
          hash = @params['secureHash']
          if !hash
            return false
          end
          hash.split(',').include? generate_secure_hash
        end

        private

        def generate_secure_hash
          fields = [@params['src'],
                    @params['prc'],
                    @params['successcode'],
                    @params['Ref'],
                    @params['PayRef'],
                    @params['Cur'],
                    @params['Amt'],
                    @params['payerAuth']]
          Paydollar.sign(fields, @options[:credential2])
        end
      end

      class Return < OffsitePayments::Return
        def success?
          @params.has_key?('Ref')
        end
      end
    end
  end
end
