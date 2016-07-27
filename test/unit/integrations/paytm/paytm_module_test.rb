require 'test_helper'
require 'openssl'
require 'base64'
require 'digest'
require 'securerandom'

class PaytmModuleTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    OffsitePayments.mode = :test
    @merchant_id = 'WorldP64425807474247'
    @secret_key = 'kbzk1DSbJiV_O3p5'
    @industry_type_id = 'Retail'
    @website = 'worldpressplg'
  end

  def test_service_url_method
    OffsitePayments.mode = :test
    assert_equal 'https://pguat.paytm.com/oltp-web/processTransaction', Paytm.service_url

    OffsitePayments.mode = :production
    assert_equal 'https://secure.paytm.in/oltp-web/processTransaction', Paytm.service_url
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
    paytm_load = { 'MID' => @merchant_id, 'ORDER_ID' => '100PT012', 'CUST_ID' => 'test@example.com', 'TXN_AMOUNT' => '10', 'CHANNEL_ID' => 'WEB', 'INDUSTRY_TYPE_ID' => @industry_type_id, 'WEBSITE' => @website, 'EMAIL' => 'test@example.com', 'MOBILE_NO' => '9999999999' }

    salt = '1234'
    keys = paytm_load.keys
    str = nil
    keys = keys.sort
    keys.each do |k|
      if str.nil?
        str = paytm_load[k].to_s
        next
      end
      str = str + '|' + paytm_load[k].to_s
    end
    str = str + '|' + salt

    check_sum = Digest::SHA256.hexdigest(str)
    check_sum += salt

    ### encrypting checksum ###
    aes = OpenSSL::Cipher::Cipher.new('aes-128-cbc')
    aes.encrypt
    aes.key = @secret_key
    aes.iv = '@@@@&&&&####$$$$'

    encrypted_data = nil
    encrypted_data = aes.update(check_sum.to_s) + aes.final
    encrypted_data = Base64.encode64(encrypted_data)

    checksum = encrypted_data.delete("\n")

    assert_equal checksum, Paytm.checksum(paytm_load, @secret_key, '1234')
  end
end
