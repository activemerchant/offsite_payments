require 'test_helper'

class PaydollarModuleTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_notification_method
    assert_instance_of Paydollar::Notification, Paydollar.notification('')
  end

  def test_return_method
    assert_instance_of Paydollar::Return, Paydollar.return('')
  end

  def test_production_url
    OffsitePayments.mode = :production
    assert_equal 'https://www.paydollar.com/b2c2/eng/payment/payShopify.jsp', Paydollar.service_url
  ensure
    OffsitePayments.mode = :test
  end

  def test_test_url
    OffsitePayments.mode = :test
    assert_equal 'https://test.paydollar.com/b2cDemo/eng/payment/payShopify.jsp', Paydollar.service_url
  end

  def test_currency_map
    assert_equal '344', Paydollar::CURRENCY_MAP['HKD']
    assert Paydollar::CURRENCY_MAP['XYZ'].nil?
  end

  def test_sign
    expected = Digest::SHA1.hexdigest('abc|def|opq')
    assert_equal expected, Paydollar.sign(['abc','def'],'opq')
  end

end
