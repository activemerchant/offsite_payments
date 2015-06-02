require 'test_helper'

class SiampayModuleTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_notification_method
    assert_instance_of Siampay::Notification, Siampay.notification('')
  end

  def test_return_method
    assert_instance_of Siampay::Return, Siampay.return('')
  end

  def test_production_url
    OffsitePayments.mode = :production
    assert_equal 'https://www.siampay.com/b2c2/eng/payment/payForm.jsp', Siampay.service_url
  ensure
    OffsitePayments.mode = :test
  end

  def test_test_url
    OffsitePayments.mode = :test
    assert_equal 'https://test.siampay.com/b2cDemo/eng/payment/payForm.jsp', Siampay.service_url
  end

  def test_currency_map
    assert_equal '344', Siampay::CURRENCY_MAP['HKD']
    assert Siampay::CURRENCY_MAP['XYZ'].nil?
  end

  def test_sign
    expected = Digest::SHA1.hexdigest('abc|def|opq')
    assert_equal expected, Siampay.sign(['abc','def'],'opq')
  end

end
