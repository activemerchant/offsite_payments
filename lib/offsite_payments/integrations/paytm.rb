module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module Paytm
      CIPHER = 'AES-128-CBC'
      SALT_ALPHABET = ['a'..'z', 'A'..'Z', '0'..'9'].flat_map { |i| i.to_a }
      SALT_LENGTH = 4
      STATIC_IV = '@@@@&&&&####$$$$'

      mattr_accessor :test_url
      mattr_accessor :production_url

      self.test_url = 'https://pguat.paytm.com/oltp-web/processTransaction'
      self.production_url = 'https://secure.paytm.in/oltp-web/processTransaction'

      def self.service_url
        OffsitePayments.mode == :production ? production_url : test_url
      end

      def self.notification(post, options = {})
        Notification.new(post, options)
      end

      def self.return(post, options = {})
        Return.new(post, options)
      end

      def self.checksum(hash, salt = nil)
        if salt.nil?
          salt = SALT_LENGTH.times.map { SALT_ALPHABET[SecureRandom.random_number(SALT_ALPHABET.length)] }.join
        end

        values = hash.sort.to_h.values
        values << salt
        Digest::SHA256.hexdigest(values.join('|')) + salt
      end

      def self.encrypt(data, key)
        aes = OpenSSL::Cipher.new(CIPHER)
        aes.encrypt
        aes.key = key
        aes.iv = STATIC_IV

        encrypted_data = aes.update(data) + aes.final
        Base64.strict_encode64(encrypted_data)
      end

      class Helper < OffsitePayments::Helper
        CHECKSUM_FIELDS = %w(MID ORDER_ID CALLBACK_URL CUST_ID TXN_AMOUNT CHANNEL_ID INDUSTRY_TYPE_ID WEBSITE MERC_UNQ_REF).freeze

        mapping :amount, 'TXN_AMOUNT'
        mapping :account, 'MID'
        mapping :order, 'MERC_UNQ_REF'

        mapping :credential3, 'INDUSTRY_TYPE_ID'
        mapping :credential4, 'WEBSITE'
        mapping :channel_id, 'CHANNEL_ID'
        mapping :return_url, 'CALLBACK_URL'
        mapping :checksum, 'CHECKSUMHASH'

        def initialize(order, account, options = {})
          super
          @options = options
          @timestamp = Time.now.strftime('%Y%m%d%H%M%S')

          add_field(mappings[:channel_id], "WEB")
          add_field 'ORDER_ID', "#{order}-#{@timestamp.to_i}"

          self.pg = 'CC'
        end

        def customer(options = {})
          customer_id =
            if options[:email].present?
              sanitize_field(options[:email])
            else
              sanitize_field(options[:phone])
            end

          add_field('CUST_ID', customer_id)
        end

        def form_fields
          sanitize_fields
          @fields.merge(mappings[:checksum] => encrypt_checksum)
        end

        def encrypt_checksum
          payload_items = {}

          CHECKSUM_FIELDS.each do |field|
            payload_items[field] = @fields[field]
          end

          Paytm.encrypt(Paytm.checksum(payload_items), @options[:credential2])
        end

        def sanitize_fields
          %w(email phone).each do |field|
            @fields[field] = sanitize_field(@fields[field])
          end
        end

        def sanitize_field(field)
          field.gsub(/[^a-zA-Z0-9\-_@\/\s.]/, '') if field
        end
      end

      class Notification < OffsitePayments::Notification
        PAYTM_RESPONSE_PARAMS = %w(MID BANKTXNID TXNAMOUNT CURRENCY STATUS RESPCODE RESPMSG TXNDATE GATEWAYNAME BANKNAME PAYMENTMODE PROMO_CAMP_ID PROMO_STATUS PROMO_RESPCODE ORDERID TXNID REFUNDAMOUNT REFID MERC_UNQ_REF CUSTID).freeze

        def initialize(post, options = {})
          super
          @secret_key = options[:credential2]
        end

        def complete?
          status == 'Completed'
        end

        def status
          if transaction_status.casecmp("TXN_SUCCESS").zero?
            'Completed'
          elsif transaction_status.casecmp("pending").zero?
            'Pending'
          else
            'Failed'
          end
        end

        def invoice_ok?(order_id)
          order_id.to_s == invoice.to_s
        end

        # Order amount should be equal to gross
        def amount_ok?(order_amount)
          BigDecimal.new(original_gross) == order_amount
        end

        # Status of transaction return from the Paytm. List of possible values:
        # <tt>TXN_SUCCESS</tt>::
        # <tt>PENDING</tt>::
        # <tt>TXN_FAILURE</tt>::
        def transaction_status
          @params['STATUS']
        end

        # ID of this transaction (Paytm transaction id)
        def transaction_id
          @params['TXNID']
        end

        # Mode of Payment
        #
        # 'CC' for credit-card
        # 'NB' for net-banking
        # 'PPI' for wallet
        def type
          @params['PAYMENTMODE']
        end

        # What currency have we been dealing with
        def currency
          @params['CURRENCY']
        end

        def item_id
          @params['MERC_UNQ_REF']
        end

        # This is the invoice which you passed to Paytm
        def invoice
          @params['MERC_UNQ_REF']
        end

        # Merchant Id provided by the Paytm
        def account
          @params['MID']
        end

        # original amount send by merchant
        def original_gross
          @params['TXNAMOUNT']
        end

        def gross
          parse_and_round_gross_amount(@params['TXNAMOUNT'])
        end

        def message
          @params['RESPMSG']
        end

        def checksum
          @params['CHECKSUMHASH']
        end

        def acknowledge
          checksum_ok?
        end

        def checksum_ok?
          return false if checksum.nil?

          normalized_data = checksum.delete("\n").tr(' ', '+')
          encrypted_data = Base64.strict_decode64(normalized_data)

          aes = OpenSSL::Cipher::Cipher.new(CIPHER)
          aes.decrypt
          aes.key = @secret_key
          aes.iv = STATIC_IV
          received_checksum = aes.update(encrypted_data) + aes.final

          salt = received_checksum[-SALT_LENGTH..-1]
          expected_params = @params.keep_if { |k| PAYTM_RESPONSE_PARAMS.include?(k) }.sort.to_h
          expected_checksum = Paytm.checksum(expected_params, salt)

          if received_checksum == expected_checksum
            @message = @params['RESPMSG']
            @params['RESPCODE'] == '01'
          else
            @message = 'Return checksum not matching the data provided'
            false
          end
        end

        private

        def parse_and_round_gross_amount(amount)
          rounded_amount = (amount.to_f * 100.0).round
          sprintf('%.2f', rounded_amount / 100.00)
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

        def status(order_id, order_amount)
          if @notification.invoice_ok?(order_id) && @notification.amount_ok?(BigDecimal.new(order_amount))
            @notification.status
          else
            'Mismatch'
          end
        end

        def success?
          status(@params['MERC_UNQ_REF'], @params['TXNAMOUNT']) == 'Completed'
        end

        def message
          @notification.message
        end
      end
    end
  end
end
