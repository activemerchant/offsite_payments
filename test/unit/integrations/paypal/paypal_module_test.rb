require 'test_helper'

class PaypalModuleTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_notification_method
    assert_instance_of Paypal::Notification, Paypal.notification('name=cody', {})
  end

  def test_test_mode
    OffsitePayments.mode = :test
    assert_equal 'https://www.sandbox.paypal.com/cgi-bin/webscr', Paypal.service_url
  end

  def test_production_mode
    OffsitePayments.mode = :production
    assert_equal 'https://www.paypal.com/cgi-bin/webscr', Paypal.service_url
  ensure
    OffsitePayments.mode = :test
  end

  def test_invalid_mode
    OffsitePayments.mode = :zoomin
    assert_raise(StandardError){ Paypal.service_url }
  ensure
    OffsitePayments.mode = :test
  end

  def test_return_method
    assert_instance_of Paypal::Return, Paypal.return('name=cody', {})
  end
end
