module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module Paytm
	
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
    salt = new_pg_generate_salt(salt_length)
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
    check_sum = new_pg_encrypt_variable(check_sum, key)
    return check_sum
  end
  
  def new_pg_verify_checksum(params, check_sum, key, salt_length = 4)
    
    if params.class != Hash
      return false
    end

    if key.empty?
      return false
    end

    if check_sum.nil? || check_sum.empty?
      return false
    end

    generated_check_sum = nil
    check_sum = new_pg_decrypt_variable(check_sum, key)

    if check_sum == false
      return false
    end
    begin
      salt = check_sum[(check_sum.length-salt_length), (check_sum.length)]
      keys = params.keys
      str = nil
      keys = keys.sort
      keys.each do |k|
        if str.nil?
          str = params[k].to_s
          next
        end
        str = str + '|' + params[k].to_s
      end
      str = str + '|' + salt
      generated_check_sum = Digest::SHA256.hexdigest(str)
      generated_check_sum = generated_check_sum + salt
    rescue Exception => e
      return false
    end
    
    if check_sum == generated_check_sum
      return true
    else
      return false
    end
  end
	
	
      mattr_accessor :test_url
      mattr_accessor :production_url

      #self.test_url = 'https://pguat.paytm.com/oltp-web/processTransaction'
      self.production_url = 'https://secure.paytm.in/oltp-web/processTransaction'

      def self.service_url
         self.production_url
      end

      def self.notification(post, options = {})
        Notification.new(post, options)
      end

      def self.return(post, options = {})
        Return.new(post, options)
      end

      def self.checksum(params, secret_key )
        return new_pg_checksum(params,secret_key)
      end

      class Helper < OffsitePayments::Helper

        CHECKSUM_FIELDS = [ 'MID', 'ORDER_ID', 'CUST_ID', 'TXN_AMOUNT', 'CHANNEL_ID', 'INDUSTRY_TYPE_ID', 'WEBSITE', 'EMAIL', 'MOBILE_NO']

        mapping :amount, 'TXN_AMOUNT'
        mapping :account, 'MID'
        mapping :order, 'ORDER_ID'
        mapping :description, 'productinfo'

        mapping :customer, :first_name => 'firstname',
          :last_name  => 'lastname',
		  :email => 'CUST_ID',
          :email => 'EMAIL',
          :phone => 'MOBILE_NO'

        mapping :billing_address, :city => 'city',
          :address1 => 'address1',
          :address2 => 'address2',
          :state => 'state',
          :zip => 'zip',
          :country => 'country'

        # Which tab you want to be open default on Paytm
        # CC (CreditCard) or NB (NetBanking)
        mapping :mode, 'pg'

        mapping :notify_url, 'notify_url'
        mapping :return_url, ['surl', 'furl']
        mapping :cancel_return_url, 'curl'
        mapping :checksum, 'hash'

        mapping :user_defined, { :var1 => 'udf1',
          :var2 => 'udf2',
          :var3 => 'udf3',
          :var4 => 'udf4',
          :var5 => 'udf5',
          :var6 => 'udf6',
          :var7 => 'udf7',
          :var8 => 'udf8',
          :var9 => 'udf9',
          :var10 => 'udf10'
        }

        def initialize(order, account, options = {})
          super
          @options = options
          self.pg = 'CC'
        end

        def form_fields
          sanitize_fields
          @fields.merge(mappings[:CHECKSUMHASH] => generate_checksum)
        end

        def generate_checksum
		  @fields.merge(mappings[:CHANNEL_ID] => "WEB")
		  @fields.merge(mappings[:INDUSTRY_TYPE_ID] => @options[:credential3])
		  @fields.merge(mappings[:WEBSITE] => @options[:credential4])
		  
          checksum_payload_items = CHECKSUM_FIELDS.map { |field| @fields[field] }

          Paytm.checksum(checksum_payload_items, @options[:credential2] )
        end

        def sanitize_fields
          ['address1', 'address2', 'city', 'state', 'country', 'productinfo', 'email', 'phone'].each do |field|
            @fields[field].gsub!(/[^a-zA-Z0-9\-_@\/\s.]/, '') if @fields[field]
          end
        end

      end

      class Notification < OffsitePayments::Notification
        def initialize(post, options = {})
          super(post, options)
          @merchant_id = options[:credential1]
          @secret_key = options[:credential2]
        end

        def complete?
          status == "Completed"
        end

        def status
          case transaction_status.downcase
          when 'TXN_SUCCESS' then 'Completed'
          when 'TXN_FAILURE ' then 'Failed'
          when 'pending' then 'Pending'
          end
        end

        def invoice_ok?( order_id )
          order_id.to_s == invoice.to_s
        end

        # Order amount should be equal to gross - discount
        def amount_ok?( order_amount, order_discount = BigDecimal.new( '0.0' ) )
          BigDecimal.new( original_gross ) == order_amount && BigDecimal.new( discount.to_s ) == order_discount
        end

        # Status of transaction return from the Paytm. List of possible values:
        # <tt>SUCCESS</tt>::
        # <tt>PENDING</tt>::
        # <tt>FAILURE</tt>::
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

               

        def checksum
          params['CHECKSUMHASH']
        end

        def message
          @message || params['error']
        end

        def acknowledge(authcode = nil)
          checksum_ok?
        end

        def checksum_ok?
			if new_pg_verify_checksum(params, checksum, @secret_key)
				if params['RESPCODE'] == '01'
					return true
				else
					@message = 'Payment failed'
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
          sprintf("%.2f", rounded_amount / 100.00)
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
          status( @params['txnid'], @params['amount'] ) == 'Completed'
        end

        def message
          @notification.message
        end
      end
    end
  end
end
