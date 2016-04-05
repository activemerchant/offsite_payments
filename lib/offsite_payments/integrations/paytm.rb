require 'openssl'
require 'base64'
require 'digest'
require 'securerandom'

module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module Paytm
<<<<<<< HEAD
      SALT_ALPHABET = ['a'..'z', 'A'..'Z', '0'..'9'].flat_map { |i| i.to_a }
=======
	
	  require 'openssl'
	  require 'base64'
	  require 'digest'
	  require 'securerandom'
	
	def new_pg_encrypt(params)
    if (params.class != Hash) || (params.keys == [])
      return false
    end
    if !params.has_key?(:key)
      return false
    end
    encrypted_data = Hash[]
    key = params.delete(:key)
    keys = params.keys
    aes = OpenSSL::Cipher::Cipher.new("aes-128-cbc")
    begin
      keys.each do |k|
        data = params[k]
        aes.encrypt
        aes.key = key
        aes.iv = '@@@@&&&&####$$$$'
        encrypted_k = aes.update(k.to_s) + aes.final
        encrypted_k = Base64.encode64(encrypted_k.to_s)
        aes.encrypt
        aes.key = key
        aes.iv = '@@@@&&&&####$$$$'
        encrypted_data[encrypted_k] = aes.update(data.to_s) + aes.final
        encrypted_data[encrypted_k] = Base64.encode64(encrypted_data[encrypted_k])
      end
    rescue Exception => e
      return false
    end
    return encrypted_data
  end
  
  
  def new_pg_encrypt_variable(data, key)
    aes = OpenSSL::Cipher::Cipher.new("aes-128-cbc")
    aes.encrypt
    aes.key = key
    aes.iv = '@@@@&&&&####$$$$'
    encrypted_data = nil
    begin
      encrypted_data = aes.update(data.to_s) + aes.final
      encrypted_data = Base64.encode64(encrypted_data)
    rescue Exception => e
      return false
    end
    return encrypted_data
  end 
  
  
  def new_pg_decrypt(params)
    if (params.class != Hash) || (params.keys == [])
      return false
    end
    if !params.has_key?(:key)
      return false
    end
    decrypted_data = Hash[]
    key = params.delete(:key)
    keys = params.keys
    aes = OpenSSL::Cipher::Cipher.new("aes-128-cbc")
    begin
      keys.each do |k|
        data = params[k]
        aes.decrypt
        aes.key = key
        aes.iv = '@@@@&&&&####$$$$'
        decrypted_k = Base64.decode64(k.to_s)
        decrypted_k = aes.update(decrypted_k.to_s) + aes.final
        if data.empty?
          decrypted_data[decrypted_k] = ""
          next
        end
        aes.decrypt
        aes.key = key
        aes.iv = '@@@@&&&&####$$$$'
        data = Base64.decode64(data)
        decrypted_data[decrypted_k] = aes.update(data) + aes.final
      end
    rescue Exception => e
      return false
    end
    return decrypted_data
  end
  
  
  def new_pg_decrypt_variable(data, key)
    aes = OpenSSL::Cipher::Cipher.new("aes-128-cbc")
    aes.decrypt
    aes.key = key
    aes.iv = '@@@@&&&&####$$$$'
    decrypted_data = nil
    begin
      decrypted_data = Base64.decode64(data.to_s)
      decrypted_data = aes.update(decrypted_data) + aes.final
    rescue Exception => e
      return false
    end
    return decrypted_data
  end


  def new_pg_generate_salt(length)
    salt = SecureRandom.urlsafe_base64(length*(3.0/4.0))
    return salt.to_s
  end
  
  
  def new_pg_checksum(params, key, salt_length = 4)
    if params.class != Hash
      return false
    end
    if key.empty?
      return false
    end
    
  end
  
  def new_pg_verify_checksum(params, check_sum, key, salt_length = 4)
    
    if params.class != Hash
      return false
    end

    if key.empty?
      return false
    end
>>>>>>> checksum bug fixed

      mattr_accessor :test_url
      mattr_accessor :production_url

      self.test_url = 'https://pguat.paytm.com/oltp-web/processTransaction'
      self.production_url = 'https://secure.paytm.in/oltp-web/processTransaction'

      def self.service_url
        OffsitePayments.mode == :production ? self.production_url : self.test_url
      end

      def self.notification(post, options = {})
        Notification.new(post, options)
      end

      def self.return(post, options = {})
        Return.new(post, options)
      end

<<<<<<< HEAD
      def self.checksum(chk_params, secret_key, salt = nil)
        if salt.nil?
          salt = 4.times.map { SALT_ALPHABET[SecureRandom.random_number(SALT_ALPHABET.length)] }.join
        end
        keys = chk_params.keys
        str = nil
        keys = keys.sort

        keys.each do |k|
          if chk_params[k].nil?
            next
          end

          if str.nil?
            str = chk_params[k].to_s
            next
          end
          str = str + '|' + chk_params[k].to_s
        end
        str = str + '|' + salt

        check_sum = Digest::SHA256.hexdigest(str)
        check_sum += salt

        ### encrypting checksum ###
        aes = OpenSSL::Cipher::AES.new('128-CBC')
        aes.encrypt
        aes.key = secret_key
        aes.iv = '@@@@&&&&####$$$$'

        encrypted_data = aes.update(check_sum.to_s) + aes.final
        check_sum = Base64.strict_encode64(encrypted_data)

        check_sum
=======
      def self.checksum(params, secret_key )
			#salt = SecureRandom.urlsafe_base64(4*(3.0/4.0))
			salt = '1234'
			keys = params.keys
			str = nil
			keys = keys.sort
			keys.each do |k|
			  if str.nil?
				str = params[k].to_s
				next
			  end
			  str = str + '|'  + params[k].to_s
			end
			str = str + '|' + salt
			check_sum = Digest::SHA256.hexdigest(str)
			check_sum = check_sum + salt
			
			### encrypting checksum ###
			aes = OpenSSL::Cipher::Cipher.new("aes-128-cbc")
			aes.encrypt
			aes.key = secret_key
			aes.iv = '@@@@&&&&####$$$$'
			
			encrypted_data = nil
			encrypted_data = aes.update(check_sum.to_s) + aes.final
			encrypted_data = Base64.encode64(encrypted_data)
			
			check_sum = encrypted_data
			#new_pg_encrypt_variable(check_sum, key)
			return check_sum
>>>>>>> checksum bug fixed
      end

      class Helper < OffsitePayments::Helper
        CHECKSUM_FIELDS = %w(MID ORDER_ID CALLBACK_URL CUST_ID TXN_AMOUNT CHANNEL_ID INDUSTRY_TYPE_ID WEBSITE MERC_UNQ_REF).freeze

        mapping :amount, 'TXN_AMOUNT'
        mapping :account, 'MID'
        mapping :order, 'MERC_UNQ_REF'

        mapping :customer, :email => 'CUST_ID'


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

        def checksum #double check check get via get call
          @params['CHECKSUMHASH']
        end

        def acknowledge(authcode = nil)
          checksum_ok?
        end

        def checksum_ok?
          check_sum = checksum.delete("\n")
          check_sum = check_sum.tr(' ', '+')

          #print debug msg if there is space in checksun
          return false if check_sum.nil?

          aes = OpenSSL::Cipher::AES.new('128-CBC')
          aes.decrypt
          aes.key = @secret_key
          aes.iv = '@@@@&&&&####$$$$'
          decrypted_data = Base64.strict_decode64(check_sum.to_s)
          decrypted_data = aes.update(decrypted_data) + aes.final
          hash_str = decrypted_data

          return false if hash_str == false

          salt = hash_str[(hash_str.length - 4), hash_str.length]
          keys = @params.keys
          str = nil
          keys = keys.sort
          keys.each do |k|
            next unless PAYTM_RESPONSE_PARAMS.include?(k)
            if str.nil?
              str = @params[k].to_s
              next
            end
            str = str + '|' + @params[k].to_s
          end
          str = str + '|' + salt
          generated_hash_str = Digest::SHA256.hexdigest(str)
          generated_hash_str += salt

          if hash_str == generated_hash_str
            if @params['RESPCODE'] == '01'
              @message = @params['RESPMSG']
              return true
            else
              @message = @params['RESPMSG']
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
          status(@params['MERC_UNQ_REF'], @params['TXNAMOUNT']) == 'Completed'
        end

        def message
          @notification.message
        end
      end
    end
  end
end
