require 'test_helper'

class EPaymentPlansModuleTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_notification_method
    assert_instance_of EPaymentPlans::Notification, EPaymentPlans.notification('name=cody')
  end

  def test_test_mode
    OffsitePayments.mode = :test
    assert_equal 'https://test.epaymentplans.com/order/purchase', EPaymentPlans.service_url
  end

  def test_production_mode
    OffsitePayments.mode = :production
    assert_equal 'https://www.epaymentplans.com/order/purchase', EPaymentPlans.service_url
  ensure
    OffsitePayments.mode = :test
  end

  def test_invalid_mode
    OffsitePayments.mode = :coolmode
    assert_raise(StandardError){ EPaymentPlans.service_url }
  ensure
    OffsitePayments.mode = :test
  end
end
