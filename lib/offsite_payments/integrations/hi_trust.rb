module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module HiTrust
      TEST_URL = 'https://testtrustlink.hitrust.com.tw/TrustLink/TrxReqForJava'
      LIVE_URL = 'https://trustlink.hitrust.com.tw/TrustLink/TrxReqForJava'

      def self.service_url
        OffsitePayments.mode == :test ? TEST_URL : LIVE_URL
      end

      def self.notification(post, options = {})
        Notification.new(post)
      end

      def self.return(query_string, options = {})
        Return.new(query_string)
      end

      class Helper < OffsitePayments::Helper
        # Transaction types
        # * Auth
        # * AuthRe
        # * Capture
        # * CaptureRe
        # * Refund
        # * RefundRe
        # * Query
        def initialize(order, account, options = {})
          super
          # Perform an authorization by default
          add_field('Type', 'Auth')

          # Capture the payment right away
          add_field('depositflag', '1')

          # Disable auto query - who knows what it does?
          add_field('queryflag', '1')

          add_field('orderdesc', 'Store purchase')
        end

        mapping :account, 'storeid'
        mapping :amount, 'amount'

        def amount=(money)
          cents = money.respond_to?(:cents) ? money.cents : money
          raise ArgumentError, "amount must be a Money object or an integer" if money.is_a?(String)
          raise ActionViewHelperError, "amount must be greater than $0.00" if cents.to_i <= 0

          add_field(mappings[:amount], cents)
        end
        # Supported currencies include:
        # * CNY：Chinese Yuan (Renminbi)
        # * TWD：New Taiwan Dollar
        # * HKD：Hong Kong Dollar
        # * USD：US Dollar
        # * AUD：Austrian Dollar
        mapping :currency, 'currency'

        mapping :order, 'ordernumber'
        mapping :description, 'orderdesc'

        mapping :notify_url, 'merUpdateURL'
        mapping :return_url, 'returnURL'
      end

      class Notification < OffsitePayments::Notification
        SUCCESS = '00'

        self.production_ips = [ '203.75.242.8' ]

        def complete?
          status == 'Completed'
        end

        def transaction_id
          params['authRRN']
        end

        def item_id
          params['ordernumber']
        end

        def received_at
          Time.parse(params['orderdate']) rescue nil
        end

        def currency
          params['currency']
        end

        def gross
          sprintf("%.2f", gross_cents.to_f / 100)
        end

        def gross_cents
          params['approveamount'].to_i
        end

        def account
          params['storeid']
        end

        def status
          params['retcode'] == SUCCESS ? 'Completed' : 'Failed'
        end

        def test?
          OffsitePayments.mode == :test
        end

        def acknowledge
          true
        end
      end

      class Return < OffsitePayments::Return
        SUCCESS = "00"
        CODES = { "00"   => "Operation completed successfully",
                  "-1"  => "Unable to initialize winsock dll.",
                  "-2"  => "Can't create stream socket.",
                  "-3"  => "No Request Message.",
                  "-4"  => "Can't connect to server.",
                  "-5"  => "Send socket error.",
                  "-6"  => "Couldn't receive data.",
                  "-7"  => "Receive Broken message.",
                  "-8"  => "Unable to initialize Envirnment.",
                  "-9"  => "Can't Read Server RSA File.",
                  "-10" => "Can't Read Client RSA File.",
                  "-11" => "Web Server error.",
                  "-12" => "Receive Message type error.",
                  "-13" => "No Request Message.",
                  "-14" => "No Response Content.",
                  "-18" => "Merchant Update URL not found.",
                  "-19" => "Server URL not find Domain or IP.",
                  "-20" => "Server URL only can fill http or https.",
                  "-21" => "Server Config File open error.",
                  "-22" => "Server RSA Key File open error.",
                  "-23" => "Server RSA Key File read error.",
                  "-24" => "Server Config File have some errors, Please to check it.",
                  "-25" => "Merchant Config File open error.",
                  "-26" => "Merchant RSA Key File open error.",
                  "-27" => "Merchant RSA Key File read error.",
                  "-28" => "Merchant Config File has some errors, Please to check it.",
                  "-29" => "Server Type is unknown.",
                  "-30" => "Comm Type is unknown.",
                  "-31" => "Input Parameter [ORDERNO] is null or empty.",
                  "-32" => "Input Parameter [STOREID] is null or empty.",
                  "-33" => "Input Parameter [ORDERDESC] is null or empty.",
                  "-34" => "Input Parameter [CURRENCY] is null or empty.",
                  "-35" => "Input Parameter [AMOUNT] is null or empty.",
                  "-36" => "Input Parameter [ORDERURL] is null or empty.",
                  "-37" => "Input Parameter [RETURNURL] is null or empty.",
                  "-38" => "Input Parameter [DEPOSIT] is null or empty.",
                  "-39" => "Input Parameter [QUERYFLAG] is null or empty.",
                  "-40" => "Input Parameter [UPDATEURL] is null or empty.",
                  "-41" => "Input Parameter [MERUPDATEURL] is null or empty.",
                  "-42" => "Input Parameter [KEY] is null or empty.",
                  "-43" => "Input Parameter [MAC] is null or empty.",
                  "-44" => "Input Parameter [CIPHER] is null or empty.",
                  "-45" => "Input Parameter [TrxType] is wrong.",
                  "-100" => "TrustLink Server is closed. Or Merchant Server IP is not consistent with TrustLink Server setting.",
                  "-101" => "TrustLink Server receives NULL.",
                  "-308" => "Order Number already exists.",
                  "positive" => "Response from Bank. Please contact with Acquirer Bank Service or HiTRUST Call Center."
                }

        def success?
          params['retcode'] == SUCCESS
        end

        def message
          return CODES["positive"] if params['retcode'].to_i > 0
          CODES[ params['retcode'] ]
        end
      end
    end
  end
end
