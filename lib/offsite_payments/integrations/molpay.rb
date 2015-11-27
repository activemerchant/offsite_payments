module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module Molpay
      mattr_accessor :acknowledge_url
      self.acknowledge_url = 'https://www.onlinepayment.com.my/MOLPay/API/chkstat/returnipn.php'

      def self.notification(post, options = {})
        Notification.new(post, options)
      end

      def self.return(query_string, options={})
        Return.new(query_string, options)
      end

      #  (Optional Parameter) = channel //will generate URL to go directly to specific channel, e.g maybank2u, cimb
      #  Please refer MOLPay API spec for the channel routing
      class Helper < OffsitePayments::Helper
        include ActiveUtils::RequiresParameters

        SUPPORTED_CURRENCIES = ['MYR', 'USD', 'SGD', 'PHP', 'VND', 'IDR', 'AUD', 'CNY', 'THB', 'GBP', 'EUR', 'HKD']

        # Defaults to en
        SUPPORTED_LANGUAGES = ['en', 'cn']

        SERVICE_URL = 'https://www.onlinepayment.com.my/MOLPay/pay/'.freeze

        mapping :account,             'merchantid'
        mapping :amount,              'amount'
        mapping :order,               'orderid'
        mapping :customer, :name  =>  'bill_name',
                           :email =>  'bill_email',
                           :phone =>  'bill_mobile'

        mapping :description,         'bill_desc'
        mapping :language,            'langcode'
        mapping :country,             'country'
        mapping :currency,            'cur'
        mapping :return_url,          'returnurl'
        mapping :notify_url,          'callbackurl'
        mapping :signature,           'vcode'

        attr_reader :amount_in_cents, :verify_key, :channel

        def credential_based_url
          service_url = SERVICE_URL + @fields[mappings[:account]] + "/"
          service_url = service_url + @channel if @channel
          service_url
        end

        def initialize(order, account, options = {})
          requires!(options, :amount, :currency, :credential2)
          @verify_key = options[:credential2] if options[:credential2]
          @amount_in_cents = options[:amount]
          @channel = options.delete(:channel)
          super
        end

        def form_fields
          add_field mappings[:signature], signature
          @fields
        end

        def amount=(money)
          unless money > 0
            raise ArgumentError, "amount must be greater than $0.00."
          end
          add_field mappings[:amount], sprintf("%.2f", money.to_f)
        end

        def currency=(cur)
          raise ArgumentError, "unsupported currency" unless SUPPORTED_CURRENCIES.include?(cur)
          add_field mappings[:currency], cur
        end

        def language=(lang)
          raise ArgumentError, "unsupported language" unless SUPPORTED_LANGUAGES.include?(lang)
          add_field mappings[:language], lang
        end

        private

        def signature
          Digest::MD5.hexdigest("#{@fields[mappings[:amount]]}#{@fields[mappings[:account]]}#{@fields[mappings[:order]]}#{@verify_key}")
        end
      end

      class Notification < OffsitePayments::Notification
        include ActiveUtils::PostsData

        def status
          case params['status']
            when '00'
              'Completed'
            when '11'
              'Failed'
            when '22'
              'Pending'
          end
        end

        def complete?
          status == 'Completed'
        end

        def item_id
          params['orderid']
        end

        def transaction_id
          params['tranID']
        end

        def account
          params["domain"]
        end

        # the money amount we received in X.2 decimal.
        def gross
          params['amount']
        end

        def currency
          params['currency']
        end

        def channel
          params['channel']
        end

        # When was this payment received by the client.
        def received_at
          params['paydate']
        end

        def auth_code
          params['appcode']
        end

        def error_code
          params['error_code']
        end

        def error_desc
          params['error_desc']
        end

        def security_key
          params['skey']
        end

        def test?
          gross.blank? && auth_code.blank? && error_code.blank? && error_desc.blank? && security_key.blank?
        end

        def status_orig
          params['status']
        end

        def acknowledge(authcode = nil)
          payload = raw + '&treq=1'
          ssl_post(Molpay.acknowledge_url, payload,
            'Content-Length' => "#{payload.size}",
            'User-Agent'     => "Shopify/OffsitePayments"
          )

          status == 'Completed' && security_key == generate_signature
        end

        protected

        def generate_signature
          key0 = Digest::MD5.hexdigest("#{transaction_id}#{item_id}#{status_orig}#{account}#{gross}#{currency}")
          Digest::MD5.hexdigest("#{received_at}#{account}#{key0}#{auth_code}#{@options[:credential2]}")
        end
      end

      class Return < OffsitePayments::Return
        def initialize(query_string, options = {})
          super
          @notification = Notification.new(query_string, options)
        end

        def success?
          @notification.acknowledge
        end

        def pending?
          @notification.status == 'Pending'
        end
      end
    end
  end
end
