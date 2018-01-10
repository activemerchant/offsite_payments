require 'test_helper'

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
    paytm_load = { 'MID' => @merchant_id, 'ORDER_ID' => '100PT012', 'CUST_ID' => 'test@example.com', 'TXN_AMOUNT' => '10', 'CHANNEL_ID' => 'WEB', 'INDUSTRY_TYPE_ID' => @industry_type_id, 'WEBSITE' => @website, 'MERC_UNQ_REF' => '100PT012', 'CALLBACK_URL' => 'http://www.shopify.com/paytmRes' }

    salt = '1234'
    values = paytm_load.sort.to_h.values
    values << salt
    check_sum = Digest::SHA256.hexdigest(values.join('|')) + salt
    ### encrypting checksum ###
    aes = OpenSSL::Cipher::AES.new('128-CBC')
    aes.encrypt
    aes.key = @secret_key
    aes.iv = '@@@@&&&&####$$$$'

    encrypted_data = aes.update(check_sum.to_s) + aes.final
    checksum = Base64.strict_encode64(encrypted_data)

    assert_equal checksum, Paytm.encrypt(Paytm.checksum(paytm_load, '1234'), @secret_key)
  end
end
