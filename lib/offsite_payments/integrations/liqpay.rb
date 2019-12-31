module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    # Documentation: https://www.liqpay.com/?do=pages&p=cnb10
    module Liqpay
      mattr_accessor :service_url
      self.service_url = 'https://liqpay.com/?do=clickNbuy'

      mattr_accessor :signature_parameter_name
      self.signature_parameter_name = 'signature'

      def self.helper(order, account, options = {})
        Helper.new(order, account, options)
      end

      def self.notification(query_string, options = {})
        Notification.new(query_string, options)
      end

      def self.return(query_string)
        Return.new(query_string)
      end

      class Helper < OffsitePayments::Helper
        def initialize(order, account, options = {})
          @secret = options.delete(:secret)
          super

          add_field 'version', '1.2'
        end

        def form_fields
          xml = "<request>
            <version>1.2</version>
            <result_url>#{@fields["result_url"]}</result_url>
            <server_url>#{@fields["server_url"]}</server_url>
            <merchant_id>#{@fields["merchant_id"]}</merchant_id>
            <order_id>#{@fields["order_id"]}</order_id>
            <amount>#{@fields["amount"]}</amount>
            <currency>#{@fields["currency"]}</currency>
            <description>#{@fields["description"]}</description>
            <default_phone>#{@fields["default_phone"]}</default_phone>
            <pay_way>card</pay_way>
            </request>".strip
          sign = Base64.encode64(Digest::SHA1.digest("#{@secret}#{xml}#{@secret}")).strip
          {"operation_xml" => Base64.encode64(xml), "signature" => sign}
        end

        mapping :account, 'merchant_id'
        mapping :amount, 'amount'
        mapping :currency, 'currency'
        mapping :order, 'order_id'
        mapping :description, 'description'
        mapping :phone, 'default_phone'

        mapping :notify_url, 'server_url'
        mapping :return_url, 'result_url'
      end

      class Notification < OffsitePayments::Notification
        def self.recognizes?(params)
          params.has_key?('amount') && params.has_key?('order_id')
        end

        def initialize(post, options = {})
          raise ArgumentError if post.blank?
          super
          @params.merge!(Hash.from_xml(Base64.decode64(xml))["response"])
        end

        def xml
          @params["operation_xml"]
        end

        def complete?
          status == 'success'
        end

        def account
          params['merchant_id']
        end

        def amount
          Money.from_amount(BigDecimal.new(gross), currency)
        end

        def item_id
          params['order_id']
        end

        def transaction_id
          params['transaction_id']
        end

        def action_name
          params['action_name'] # either 'result_url' or 'server_url'
        end

        def version
          params['version']
        end

        def sender_phone
          params['sender_phone']
        end

        def security_key
          params[OffsitePayments::Integrations::Liqpay.signature_parameter_name]
        end

        def gross
          params['amount']
        end

        def currency
          params['currency']
        end

        def status
          params['status'] # 'success', 'failure' or 'wait_secure'
        end

        def code
          params['code']
        end

        def generate_signature_string
          "#{@options[:secret]}#{Base64.decode64(xml)}#{@options[:secret]}"
        end

        def generate_signature
          Base64.encode64(Digest::SHA1.digest(generate_signature_string)).strip
        end

        def acknowledge(authcode = nil)
          security_key == generate_signature
        end
      end

      class Return < OffsitePayments::Return
        def self.recognizes?(params)
          params.has_key?('amount') && params.has_key?('order_id')
        end

        def initialize(post)
          super
          xml = Base64.decode64(@params["operation_xml"])
          @params.merge!(Hash.from_xml(xml)["response"])
        end

        def complete?
          status == 'success'
        end

        def account
          params['merchant_id']
        end

        def amount
          BigDecimal.new(gross)
        end

        def item_id
          params['order_id']
        end

        def transaction_id
          params['transaction_id']
        end

        def action_name
          params['action_name'] # either 'result_url' or 'server_url'
        end

        def version
          params['version']
        end

        def sender_phone
          params['sender_phone']
        end

        def security_key
          params[OffsitePayments::Integrations::Liqpay.signature_parameter_name]
        end

        def gross
          params['amount']
        end

        def currency
          params['currency']
        end

        def status
          params['status'] # 'success', 'failure' or 'wait_secure'
        end

        def code
          params['code']
        end

        def generate_signature_string
          ['', version, @options[:secret], action_name, sender_phone, account, gross, currency, item_id, transaction_id, status, code, ''].flatten.compact.join('|')
        end

        def generate_signature
          Base64.encode64(Digest::SHA1.digest(generate_signature_string)).gsub(/\n/, '')
        end

        def acknowledge(authcode = nil)
          security_key == generate_signature
        end
      end
    end
  end
end
