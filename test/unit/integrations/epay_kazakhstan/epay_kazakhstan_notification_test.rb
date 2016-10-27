require 'test_helper'

class EpayKazakhstanNotificationTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    EpayKazakhstan.configure do |config|
      config.merchant_certificate_id = '00C182B189'
      config.merchant_name = 'Test shop'
      config.private_key_pass = 'nissan'
      config.merchant_id = '92061101'
      config.cert_file_path = File.expand_path('../kkbca.cer', __FILE__)
      config.private_key_path = File.expand_path('../test_prv.pem', __FILE__)
    end
    @notification = EpayKazakhstan.notification(http_raw_data)
  end

  # def test_aknowledge
  #   assert @notification.acknowledge
  # end

  def test_has_error?
    assert_equal @notification.has_error?, false
  end

  def test_customer
    customer = @notification.customer
    assert_equal customer.name, "Ucaf Test Maest"
    assert_equal customer.email, "SeFrolov@kkb.kz"
    assert_equal customer.phone, ""
  end

  def test_order
    order = @notification.order
    assert_equal order.amount, 1000
    assert_equal order.id, '0706172110'
    assert_equal order.currency, '398'
  end

  def test_payment
    payment = @notification.payment
    assert (payment.timestamp - Time.parse('2006-07-06 17:21:50')) == 0
    assert_equal payment.amount, 1000
    assert_equal payment.reference, "618704198173"
    assert_equal payment.response_code, "00"
    assert_equal payment.merchant_id, "92056001"
    assert_equal payment.approval_code, "447753"
  end

  def test_bank_name
    assert_equal @notification.bank_name, "Kazkommertsbank JSC"
  end

  def test_merchant_name
    assert_equal @notification.merchant_name, "test merch"
  end

  private

  def http_raw_data
    {
      'response' => '<document><bank name="Kazkommertsbank JSC"><customer name="Ucaf Test Maest" mail="SeFrolov@kkb.kz" phone=""><merchant cert_id="00C182B189" name="test merch"><order order_id="0706172110" amount="1000" currency="398"><department merchant_id="92056001" amount="1000"/></order></merchant><merchant_sign type="RSA"/></customer><customer_sign type="RSA"/><results timestamp="2006-07-06 17:21:50"><payment merchant_id="92056001" amount="1000" reference="618704198173" approval_code="447753" response_code="00"/></results></bank><bank_sign cert_id="00C18327E8" type="SHA/RSA">xjJwgeLAyWssZr3/gS7TI/xaajoF3USk0B/ZfLv6SYyY/3H8tDHUiyGcV7zDO5+rINwBoTn7b9BrnO/kvQfebIhHbDlCSogz2cB6Qa2ELKAGqs8aDZDekSJ5dJrgmFT6aTfgFgnZRmadybxTMHGR6cn8ve4m0TpQuaPMQmKpxTI=</bank_sign></document>'
    }
  end
end