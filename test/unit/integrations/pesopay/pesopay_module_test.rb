require 'test_helper'

class PesopayModuleTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_notification_method
    assert_instance_of Pesopay::Notification, Pesopay.notification('')
  end

  def test_return_method
    assert_instance_of Pesopay::Return, Pesopay.return('')
  end

  def test_production_url
    OffsitePayments.mode = :production
    assert_equal 'https://www.pesopay.com/b2c2/eng/payment/payForm.jsp', Pesopay.service_url
  ensure
    OffsitePayments.mode = :test
  end

  def test_test_url
    OffsitePayments.mode = :test
    assert_equal 'https://test.pesopay.com/b2cDemo/eng/payment/payForm.jsp', Pesopay.service_url
  end

  def test_currency_map
    assert_equal '344', Pesopay::CURRENCY_MAP['HKD']
    assert Pesopay::CURRENCY_MAP['XYZ'].nil?
  end

  def test_sign
    expected = Digest::SHA1.hexdigest('abc|def|opq')
    assert_equal expected, Pesopay.sign(['abc','def'],'opq')
  end

end
