require 'test_helper'
require 'openssl'
require 'base64'
require 'digest'
require 'securerandom'
	
	
  

class PaytmModuleTest < Test::Unit::TestCase
  include OffsitePayments::Integrations
  
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

  def setup
    OffsitePayments.mode = :test
    @merchant_id = 'WorldP64425807474247'
    @secret_key = 'kbzk1DSbJiV_O3p5'
	@industry_type_id = 'Retail'
	@website = 'worldpressplg'
  end

  def test_service_url_method
    OffsitePayments.mode = :test
    assert_equal "https://pguat.paytm.com/oltp-web/processTransaction", Paytm.service_url

    OffsitePayments.mode = :production
    assert_equal "https://secure.paytm.in/oltp-web/processTransaction", Paytm.service_url
  ensure
    OffsitePayments.mode = :test
  end

  def test_return_method
    assert_instance_of Paytm::Return, Paytm.return('name=foo', {})
  end

  def test_notification_method
    assert_instance_of Paytm::Notification, Paytm.notification('name=foo', {})
  end

  def test_checksum_method
    paytm_load = { 'MID' => @merchant_id, 'ORDER_ID' => '100PT012' , 'CUST_ID' => 'test@example.com', 'TXN_AMOUNT'=> '10', 'CHANNEL_ID' => 'WEB' , 'INDUSTRY_TYPE_ID' => @industry_type_id, 'WEBSITE' => @website , 'EMAIL' => 'test@example.com', 'MOBILE_NO' => '9999999999']} 
    checksum = new_pg_checksum(paytm_load, @secret_key)
    assert_equal checksum, Paytm.checksum(paytm_load, @secret_key)
  end
end
