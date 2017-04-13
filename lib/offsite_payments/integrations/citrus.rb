module OffsitePayments
  module Integrations
    module Citrus
      def self.helper(order, account, options = {})
        Helper.new(order, account, options)
      end

      def self.notification(post, options = {})
        Notification.new(post, options)
      end

      def self.return(query_string, options = {})
        Return.new(query_string, options)
      end

      def self.checksum(secret_key, payload_items )
        digest = OpenSSL::Digest.new('sha1')
        OpenSSL::HMAC.hexdigest(digest, secret_key, payload_items)
      end

      class Helper < OffsitePayments::Helper
        mapping :order, 'merchantTxnId'
        mapping :amount, 'orderAmount'
        mapping :account, 'merchantAccessKey'
        mapping :credential2, 'secret_key'
        mapping :credential3, 'pmt_url'
        mapping :currency, 'currency'

        mapping :customer, :first_name => 'firstName',:last_name => 'lastName', :email => 'email', :phone => 'mobileNo'

        mapping :billing_address, :city => 'addressCity', :address1 => 'addressStreet1', :address2 => 'addressStreet2',:state => 'addressState',:zip => 'addressZip', :country => 'addressCountry'

        mapping :checksum, 'secSignature'
        mapping :return_url, 'returnUrl'

        SANDBOX_URL = 'https://sandbox.citruspay.com/'.freeze
        STAGING_URL = 'https://stg.citruspay.com/'.freeze
        PRODUCTION_URL = 'https://www.citruspay.com/'.freeze

        def credential_based_url
          pmt_url = @fields['pmt_url']
          case OffsitePayments.mode
          when :production
            PRODUCTION_URL + pmt_url
          when :test
            SANDBOX_URL    + pmt_url
          when :staging
            STAGING_URL    + pmt_url
          else
            raise StandardError, "Integration mode set to an invalid value: #{mode}"
          end
        end

        def initialize(order, account, options = {})
          super
          add_field 'paymentMode', 'NET_BANKING'
          add_field 'reqtime', (Time.now.to_i * 1000).to_s
        end

        def form_fields
          @fields.merge(mappings[:checksum] => generate_checksum)
        end

        def generate_checksum
          checksum_fields = @fields["pmt_url"] + @fields["orderAmount"].to_s + @fields["merchantTxnId"] + @fields["currency"]
          Citrus.checksum(@fields["secret_key"],  checksum_fields )
        end
      end

      class Notification < OffsitePayments::Notification
        def initialize(post, options = {})
          super(post, options)
          @secret_key = options[:credential2]
        end

        def complete?
          status == "Completed" || status == 'Canceled'
        end

        def status
          @status ||= if checksum_ok?
            if transaction_id.blank?
              'Invalid'
            else
              case transaction_status.downcase
              when 'success' then 'Completed'
              when 'canceled' then 'Failed'
              end
            end
          else
            'Tampered'
          end
        end

        def invoice_ok?( order_id )
          order_id.to_s == invoice.to_s
        end

        def amount_ok?(order_amount)
          amount == Money.from_amount(order_amount, currency)
        end

        def item_id
          params['TxId']
        end

        def invoice
          item_id
        end

        # Status of transaction return from the Citrus. List of possible values:
        # <tt>SUCCESS</tt>::
        # <tt>CANCELED</tt>::
        def transaction_status
          params['TxStatus']
        end

        def gross
          params['amount']
        end

        def amount
          Money.from_amount(BigDecimal.new(gross), currency)
        end

        def transaction_id
          params['pgTxnNo']
        end

        def issuerrefno
          params['issuerRefNo']
        end

        def authidcode
          params['authIdCode']
        end

        def pgrespcode
          params['pgRespCode']
        end

        def checksum
          params['signature']
        end

        def paymentmode
          params['paymentMode']
        end

        def currency
          params['currency']
        end

        def customer_email
          params['email']
        end

        def customer_phone
          params['mobileNo']
        end

        def customer_first_name
          params['firstName']
        end

        def customer_last_name
          params['lastName']
        end

        def customer_address
          { :address1 => params['addressStreet1'], :address2 => params['addressStreet2'],
            :city => params['addressCity'], :state => params['addressState'],
            :country => params['addressCountry'], :zip => params['addressZip'] }
        end

        def message
          @message || params['TxMsg']
        end

        def acknowledge(authcode = nil)
          checksum_ok?
        end

        def checksum_ok?
          fields = [invoice, transaction_status, sprintf('%.2f', amount), transaction_id, issuerrefno, authidcode, customer_first_name, customer_last_name, pgrespcode, customer_address[:zip]].join

          unless Citrus.checksum(@secret_key, fields ) == checksum
            @message = 'checksum mismatch...'
            return false
          end
          true
        end
      end

      class Return < OffsitePayments::Return
        def initialize(query_string, options = {})
          super
          @notification = Notification.new(query_string, options)
        end

        def transaction_id
          @notification.transaction_id
        end

        def status( order_id, order_amount )
          if @notification.invoice_ok?( order_id ) && @notification.amount_ok?( BigDecimal.new(order_amount) )
            @notification.status
          else
            'Mismatch'
          end
        end

        def success?
          status( @params['TxId'], @params['amount'] ) == 'Completed'
        end

        def message
          @notification.message
        end

        def cancelled?
          @notification.status == 'Failed'
        end
      end
    end
  end
end
