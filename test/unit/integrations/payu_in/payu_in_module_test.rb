require 'test_helper'

class PayuInModuleTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    OffsitePayments.mode = :test
    @merchant_id = 'merchant_id'
    @secret_key = 'secret'
  end

  def test_service_url_method
    OffsitePayments.mode = :test
    assert_equal "https://test.payu.in/_payment.php", PayuIn.service_url

    OffsitePayments.mode = :production
    assert_equal "https://secure.payu.in/_payment.php", PayuIn.service_url
  ensure
    OffsitePayments.mode = :test
  end

  def test_return_method
    assert_instance_of PayuIn::Return, PayuIn.return('name=foo', {})
  end

  def test_notification_method
    assert_instance_of PayuIn::Notification, PayuIn.notification('name=foo', {})
  end

  def test_checksum_method
    payu_load = "order_id|10.00|Product Info|Payu-Admin|test@example.com||||||||||"
    checksum = Digest::SHA512.hexdigest([@merchant_id, payu_load, @secret_key].join("|"))
    assert_equal checksum, PayuIn.checksum(@merchant_id, @secret_key, payu_load.split("|", -1))
  end
end
