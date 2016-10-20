module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module Paytm
      require 'openssl'
      require 'base64'
      require 'digest'
      require 'securerandom'

      $DEBUG = false
      #$RUN_UNIT_TEST = 0 #do not make this true, in normal 

      mattr_accessor :test_url
      mattr_accessor :production_url

      self.test_url = 'https://pguat.paytm.com/oltp-web/processTransaction'
      self.production_url = 'https://secure.paytm.in/oltp-web/processTransaction'

      def self.service_url
        # self.production_url
        OffsitePayments.mode == :production ? production_url : test_url
      end

      def self.notification(post, options = {})
        Notification.new(post, options)
      end

      def self.return(post, options = {})
        Return.new(post, options)
      end

      def self.checksum(chkParams, secret_key, salt = nil)
        if salt.nil?
        	o = [('a'..'z'), ('A'..'Z'), ('0'..'9')].map { |i| i.to_a }.flatten
			salt = (0...4).map { o[Random.rand(o.length)] }.join
        end
        keys = chkParams.keys
        str = nil
        keystr = nil
        keys = keys.sort
        keys.each do |k|
          
          if chkParams[k].nil?
            next
          end
          
          if str.nil?
            str = chkParams[k].to_s
            keystr = k.to_s+"="+chkParams[k].to_s+"&"
            next
          end
          str = str + '|' + chkParams[k].to_s
          keystr = keystr + k.to_s+"="+chkParams[k].to_s+"&"
        end
        str = str + '|' + salt

        if $DEBUG 
        	puts "KeyMAp: " + keystr + ";   Values: "+str+"; salt: " + salt + ";"
        end

        check_sum = Digest::SHA256.hexdigest(str)
        check_sum += salt

        ### encrypting checksum ###
        aes = OpenSSL::Cipher::Cipher.new('aes-128-cbc')
        aes.encrypt
        aes.key = secret_key
        aes.iv = '@@@@&&&&####$$$$'

		
        encrypted_data = aes.update(check_sum.to_s) + aes.final
        encrypted_data = Base64.encode64(encrypted_data)

        check_sum = encrypted_data.delete("\n")
        check_sum
      end

      class Helper < OffsitePayments::Helper
        CHECKSUM_FIELDS = %w(MID ORDER_ID CALLBACK_URL CUST_ID TXN_AMOUNT CHANNEL_ID INDUSTRY_TYPE_ID WEBSITE MOBILE_NO).freeze

        mapping :amount, 'TXN_AMOUNT'
        mapping :account, 'MID'
        mapping :order, 'ORDER_ID'

        mapping :customer, :email => 'CUST_ID',
                           :phone => 'MOBILE_NO'

        # Which tab you want to be open default on Paytm
        # CC (CreditCard) or NB (NetBanking)
        mapping :mode, 'pg'
        mapping :credential3, 'INDUSTRY_TYPE_ID'
        mapping :credential4, 'WEBSITE'
        mapping :channel_id, 'CHANNEL_ID'
        mapping :return_url, 'CALLBACK_URL'
        mapping :checksum, 'CHECKSUMHASH'


        def initialize(order, account, options = {})
          super
          @options = options
          add_field(mappings[:channel_id], "WEB")
          self.pg = 'CC'
        end

        def form_fields
          sanitize_fields
          @fields.merge(mappings[:checksum] => generate_checksum)
        end

        def generate_checksum
          
          checksum_payload_items = Hash.new
          CHECKSUM_FIELDS.each do |field|
              checksum_payload_items[field] = @fields[field]
          end          
          Paytm.checksum(checksum_payload_items, @options[:credential2])
        end

        def sanitize_fields
          %w(email phone).each do |field|
            @fields[field].gsub!(/[^a-zA-Z0-9\-_@\/\s.]/, '') if @fields[field]
          end
        end

      end



      class Notification < OffsitePayments::Notification
        PAYTM_RESPONSE_PARAMS = %w(SUBS_ID MID BANKTXNID TXNAMOUNT CURRENCY STATUS RESPCODE RESPMSG TXNDATE GATEWAYNAME BANKNAME PAYMENTMODE PROMO_CAMP_ID PROMO_STATUS PROMO_RESPCODE ORDERID TXNID REFUNDAMOUNT REFID).freeze
        def initialize(post, options = {})
          super(post, options)
          @merchant_id = options[:credential1]
          @secret_key = options[:credential2]
        end

        def complete?
          status == 'Completed'
        end

        def status
          if transaction_status.casecmp("TXN_SUCCESS").zero? 
            return 'Completed'
          elsif transaction_status.casecmp("pending").zero? 
            return 'Pending'
          else
            return 'Failed'
          end
        end

        def invoice_ok?(order_id)
          order_id.to_s == invoice.to_s
        end

        # Order amount should be equal to gross - discount
        def amount_ok?(order_amount, _order_discount = BigDecimal.new('0.0'))
          BigDecimal.new(original_gross) == order_amount
        end

        # Status of transaction return from the Paytm. List of possible values:
        # <tt>TXN_SUCCESS</tt>::
        # <tt>pending</tt>::
        # <tt>TXN_FAILURE</tt>::
        def transaction_status
          params['STATUS']
        end

        # ID of this transaction (Paytm transaction id)
        def transaction_id
          params['TXNID']
        end

        # Mode of Payment
        #
        # 'CC' for credit-card
        # 'NB' for net-banking

        def type
          params['PAYMENTMODE']
        end

        # What currency have we been dealing with
        def currency
          'INR'
        end

        def item_id
          params['ORDERID']
        end

        # This is the invoice which you passed to Paytm
        def invoice
          params['ORDERID']
        end

        # Merchant Id provided by the Paytm
        def account
          params['MID']
        end

        # original amount send by merchant
        def original_gross
          params['TXNAMOUNT']
        end

        def gross
          parse_and_round_gross_amount(params['TXNAMOUNT'])
        end

        def checksum #double check check get via get call
          params['CHECKSUMHASH'].tr(' ', '+')
        end

        def message
          @message || params['error']
        end

        def acknowledge(_authcode = nil)
          checksum_ok?
        end

        def checksum_ok?
          check_sum = checksum.delete("\n")
          check_sum = check_sum.tr(' ', '+')

          if $DEBUG   
            if check_sum.include? " "
              puts "checksum contain Space : "+check_sum
            end
          end
          #print debug msg if there is space in checksun

          return false if check_sum.nil?

          
          aes = OpenSSL::Cipher::Cipher.new('aes-128-cbc')
          aes.decrypt
          aes.key = @secret_key
          aes.iv = '@@@@&&&&####$$$$'
          decrypted_data = Base64.decode64(check_sum.to_s)
          decrypted_data = aes.update(decrypted_data) + aes.final
          hashStr = decrypted_data

          return false if hashStr == false

          salt = hashStr[(hashStr.length - 4), hashStr.length]
          keys = params.keys
          str = nil
          keystr = nil
          keys = keys.sort
          keys.each do |k|
            next unless PAYTM_RESPONSE_PARAMS.include?(k)
            if str.nil?
              str = params[k].to_s
              keystr = k.to_s
              next
            end
            str = str + '|' + params[k].to_s
            keystr = keystr + '|' + k.to_s
          end
          str = str + '|' + salt
          generated_hashStr = Digest::SHA256.hexdigest(str)
          generated_hashStr += salt
          if $DEBUG 
           	puts "KeyMAp: " + keystr + ";  Values: " + str + ";"
          end
          if hashStr == generated_hashStr
            if params['RESPCODE'] == '01'
              @message = params['RESPMSG']
              return true
            else
              @message = params['RESPMSG']
              return false
            end
          else
            @message = 'Return checksum not matching the data provided'
            return false
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
          status(@params['ORDERID'], @params['TXNAMOUNT']) == 'Completed'
        end

        def message
          @notification.message
        end
      end
    end
  end
end