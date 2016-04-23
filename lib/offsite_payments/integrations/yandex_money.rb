require 'net/http'

module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module YandexMoney

      # Start integration with yandex.money here:
      # https://money.yandex.ru/joinups

      # Shop example:
      # https://github.com/yurijmi/yandex_money_offsite_payments_demo

      mattr_accessor :production_url, :test_url

      self.production_url = 'https://money.yandex.ru/eshop.xml'
      self.test_url       = 'https://demomoney.yandex.ru/eshop.xml'

      def self.service_url
        case OffsitePayments.mode
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

      class Helper < OffsitePayments::Helper
        mapping :account,     'customerNumber'
        mapping :amount,      'sum'
        mapping :order,       'orderNumber'
        mapping :error_url,   'shopFailURL'
        mapping :return_url,  'shopSuccessURL'
        mapping :description, 'orderDetails'

        mapping :customer, :email      => 'cps_email',
                           :phone      => 'cps_phone'

        # additional yandex.money parameters
        mapping :scid,          'scid'
        mapping :shopId,        'shopId'
        mapping :shopArticleId, 'shopArticleId'
      end

      class Notification < OffsitePayments::Notification
        def initialize(post, options = {})
          super
          @response_code = '200'
        end

        def complete?
          params['_raw_action'] == 'paymentAviso'
        end

        def item_id
          params['_raw_orderNumber']
        end

        def transaction_id
          params['_raw_invoiceId']
        end

        # When was this payment received by the client.
        def received_at
          params['_raw_orderCreatedDatetime']
        end

        def currency
          params['_raw_orderSumCurrencyPaycash']
        end

        def payer_email
          params['_raw_cps_email']
        end

        # the money amount we received in X.2 decimal.
        def gross
          params['_raw_orderSumAmount'].to_f
        end

        def customer_id
          params['_raw_customerNumber']
        end

        def set_response(code)
          @response_code = code
        end

        def get_response()
          @response_code
        end

        # Was this a test transaction?
        def test?
          false
        end

        def status
          case params['_raw_action']
            when 'checkOrder'
              'pending'
            when 'paymentAviso'
              'completed'
            else 'unknown'
          end
        end

        def response
          shop_id = params['_raw_shopId']
          method = params['_raw_action']
          dt = Time.now.iso8601
          "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" +
              "<#{method}Response performedDatetime=\"#{dt}\" code=\"#{@response_code}\"" +
              " invoiceId=\"#{transaction_id}\" shopId=\"#{shop_id}\"/>"
        end

        # Acknowledge the transaction to YandexMoney. This method has to be called after a new
        # apc arrives. YandexMoney will verify that all the information we received are correct and will return a
        # ok or a fail.
        #
        # Example:
        #
        #   def ipn
        #     notify = YandexMoneyNotification.new(request.raw_post)
        #
        #     if notify.acknowledge(authcode)
        #       if notify.complete?
        #         ... process order ...
        #       end
        #     else
        #       ... log possible hacking attempt ...
        #     end
        #     render text: notify.response
        #

        def acknowledge(authcode = nil)
          string = [params['_raw_action'],
                    params['_raw_orderSumAmount'],
                    params['_raw_orderSumCurrencyPaycash'],
                    params['_raw_orderSumBankPaycash'],
                    params['_raw_shopId'],
                    params['_raw_invoiceId'],
                    params['_raw_customerNumber'],
                    authcode
          ].join(';')

          digest = Digest::MD5.hexdigest(string)
          res = params['_raw_md5'] == digest.upcase
          if res
            @response_code = '0'
          else
            @response_code = '1'
          end
        end

        private

        # Take the posted data and move the relevant data into a hash
        def parse(post)
          @raw = post.to_s
          for line in @raw.split('&')
            key, value = *line.scan( %r{^([A-Za-z0-9_.-]+)\=(.*)$} ).flatten
            # to divide raw values from other
            params['_raw_' + key] = CGI.unescape(value.to_s) if key.present?
          end
        end
      end
    end
  end
end
