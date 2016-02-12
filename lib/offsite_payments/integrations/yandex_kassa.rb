module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module YandexKassa

      mattr_accessor :test_url
      self.test_url = 'https://demomoney.yandex.ru/eshop.xml'

      mattr_accessor :production_url
      self.production_url = ''

      def self.service_url
        mode = OffsitePayments.mode

        case mode
        when :production
          self.production_url
        when :test
          self.test_url
        else
          raise StandardError, 'Integration mode set to an invalid value: #{mode}'
        end
      end

      def self.notification(post, options = {})
        Notification.new(post, options)
      end

      def self.helper(order, account, options = {})
        Helper.new(order, account, options)
      end

      class Helper < OffsitePayments::Helper
        mapping :account,     'customerNumber'
        mapping :amount,      'sum'
        mapping :order,       'orderNumber'
        mapping :customer,    :email      => 'cps_email',
                              :phone      => 'cps_phone'

        mapping :success_url, 'shopSuccessURL'
        mapping :fail_url,    'shopFailURL'

        mapping :scid,        'scid'
        mapping :shop_id,     'shopId'
      end

      class Notification < OffsitePayments::Notification
        def currency
          id, _ = Money::Currency.table.find {|key, currency| currency[:iso_numeric] == shop_sum_currency_paycash }
          id
        end

        def signature_string
          [action, order_sum_amount, order_sum_currency_paycash, order_sum_bank_paycash, shop_id, invoice_id, customer_number]
        end

        def generate_signature(shop_password)
          Digest::MD5.hexdigest((signature_string << shop_password).join(','))
        end

        def request_datetime
          params['requestDatetime']
        end
        def action
          params['action']
        end
        def md5
          params['md5']
        end
        def shop_id
          params['shopId']
        end
        def shop_article_id
          params['shopArticleId']
        end
        def invoice_id
          params['invoiceId']
        end
        def order_number
          params['orderNumber']
        end
        def customer_number
          params['customerNumber']
        end
        def order_created_datetime
          params['orderCreatedDatetime']
        end
        def order_sum_amount
          params['orderSumAmount']
        end
        def order_sum_currency_paycash
          params['orderSumCurrencyPaycash'] 
        end
        def order_sum_bank_paycash
          params['orderSumBankPaycash']
        end
        def shop_sum_amount
          params['shopSumAmount']
        end
        def shop_sum_currency_paycash
          params['shopSumCurrencyPaycash']
        end
        def shop_sum_bank_paycash
          params['shopSumBankPaycash']
        end
        def payment_payer_code
          params['paymentPayerCode']
        end
        def payment_type
          params['paymentType']
        end

        def complete?
          case action
          when 'checkOrder'
            'pending'
          when 'paymentAviso'
            'complete'
          else
            'unknown'
          end
#          params['']
        end

#        def currency
#          shop_sum_currency_paycash
#        end

        def item_id
          shop_article_id
#          params['']
        end

        def transaction_id
          shop_invoice_id
#          params['']
        end

        # When was this payment received by the client.
        def received_at
          request_datetime
#          params['']
        end

#        def payer_email
#          params['']
#        end

#        def receiver_email
#          params['']
#        end

        def security_key
          md5.to_s.downcase
#          params['']
        end

        # the money amount we received in X.2 decimal.
        def gross
          shop_sum_amount.to_f
#          params['']
        end

        def status
          'success'
#          params['']
        end

        # Acknowledge the transaction to YandexKassa. This method has to be called after a new
        # apc arrives. YandexKassa will verify that all the information we received are correct and will return a
        # ok or a fail.
        #
        # Example:
        #
        #   def ipn
        #     notify = YandexKassaNotification.new(request.raw_post)
        #
        #     if notify.acknowledge
        #       ... process order ... if notify.complete?
        #     else
        #       ... log possible hacking attempt ...
        #     end
        def acknowledge(authcode = nil)
          (security_key == generate_signature(authcode))
#          payload = raw
#
#          uri = URI.parse(YandexKassa.notification_confirmation_url)
#
#          request = Net::HTTP::Post.new(uri.path)
#
#          request['Content-Length'] = "#{payload.size}"
#          request['User-Agent'] = "Active Merchant -- http://activemerchant.org/"
#          request['Content-Type'] = "application/x-www-form-urlencoded"
#
#          http = Net::HTTP.new(uri.host, uri.port)
#          http.verify_mode    = OpenSSL::SSL::VERIFY_NONE unless @ssl_strict
#          http.use_ssl        = true
#
#          response = http.request(request, payload)
#
#          # Replace with the appropriate codes
#          raise StandardError.new("Faulty YandexKassa result: #{response.body}") unless ["AUTHORISED", "DECLINED"].include?(response.body)
#          response.body == "AUTHORISED"
        end

#        private
#
#        # Take the posted data and move the relevant data into a hash
#        def parse(post)
#          @raw = post.to_s
#          for line in @raw.split('&')
#            key, value = *line.scan( %r{^([A-Za-z0-9_.-]+)\=(.*)$} ).flatten
#            params[key] = CGI.unescape(value.to_s) if key.present?
#          end
#        end
      end
    end
  end
end
