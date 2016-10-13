module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    # Documentation:
    # http://wiki.onpay.ru/doku.php?id=description_of_the_api
    module Onpay
      SERVICE_URL = "https://secure.onpay.ru/pay/".freeze

      def self.helper(order, account, options = {})
        Helper.new(order, account, options)
      end

      def self.notification(query_string, options = {})
        Notification.new(query_string, options)
      end

      # def self.return(query_string)
      #   Return.new(query_string)
      # end

      module Common
        def pay?
          !params["payment"].try(:[], "amount").nil?
        end

        def generate_signature_string
          if pay?
            "pay;#{params["pay_for"]};#{params["payment"]["amount"]};#{params["payment"]["way"]};#{params["balance"]["amount"]};#{params["balance"]["way"]};#{secret}"
          else
            "check;#{params['pay_for']};#{params['amount']};#{params['way']};#{params['mode']};#{secret}"
          end
        end

        def generate_signature
          Digest::SHA1.hexdigest(generate_signature_string)
        end
      end

      class Helper < OffsitePayments::Helper
        #include Common

        def initialize(order, account, options = {})
          @account = account
          @onpay_options = options.dup

          options.delete(:description)
          options.delete(:fail_url)
          options.delete(:success_url)
          options.delete(:result_url)
          options.delete(:pay_mode)
          super
          @onpay_options.each do |key, value|
            add_field mappings[key], value
          end
          add_field "price", "%.1f" % @onpay_options[:amount].to_f
        end

        def credential_based_url
          SERVICE_URL + @account
        end

        def form_fields
          @fields
        end

        def params
          @fields
        end

        mapping :pay_mode, 'pay_mode'
        mapping :order, 'pay_for'
        mapping :fail_url, 'url_fail'
        mapping :success_url, 'url_success'
      end

      class Notification < OffsitePayments::Notification
        include Common

        def parse(post)
          @raw = post.to_s
          @params = JSON.parse(post)
        rescue JSON::ParserError
          @params = {}
        end

        def recognizes?
          params.has_key?('pay_for')
        end

        def amount
          BigDecimal.new(params['payment']["amount"].to_s)
        end

        def key_present?
          params["signature"].present?
        end

        def item_id
          params['pay_for']
        end

        def payment_id
          params["payment"].try(:[], 'id')
        end

        def gross
          (params['amount'] || params['payment'].try(:[], 'amount')).to_s
        end

        def security_key
          params["signature"]
        end

        def secret
          @options[:secret]
        end

        def acknowledge(authcode = nil)
          (security_key == generate_signature)
        end

        def success_response
          pay? ? success_pay_response : success_check_response
        end

        def fail_response
          pay? ? fail_pay_response : fail_check_response
        end

        def success_check_response(*args)
          {
            "status":true,
            "pay_for":item_id,
            "signature":check_response_signature
          }.to_json
        end

        def success_pay_response(*args)
          {
            "status":true,
            "pay_for":item_id,
            "signature":pay_response_signature
          }.to_json
        end

        def fail_check_response(*args)
          {
            "status":false,
            "pay_for":item_id,
            "signature":check_response_signature(false)
          }.to_json
        end

        def fail_pay_response(*args)
          {
            "status":false,
            "pay_for":item_id,
            "signature":pay_response_signature(false)
          }.to_json
        end

        def check_response_signature_string(res)
          "check;#{res};#{item_id};#{secret}"
        end

        def check_response_signature(res = true)
          Digest::SHA1.hexdigest(check_response_signature_string(res))
        end

        def pay_response_signature_string(res)
          "pay;#{res};#{item_id};#{secret}"
        end

        def pay_response_signature(res = true)
          Digest::SHA1.hexdigest(pay_response_signature_string(res))
        end
      end

    end
  end
end
