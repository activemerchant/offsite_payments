require 'test_helper'

class WorldPayModuleTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    OffsitePayments.mode = :test
  end

  def test_service_url_in_test_mode
    assert_equal 'https://secure-test.worldpay.com/wcc/purchase', WorldPay.service_url
  end

  def test_service_url_in_production_mode
    OffsitePayments.mode = :production
    assert_equal 'https://secure.worldpay.com/wcc/purchase', WorldPay.service_url
  ensure
    OffsitePayments.mode = :test
  end

  def test_notification_method
    assert_instance_of WorldPay::Notification, WorldPay.notification('name=Andrew White', {})
  end
end
