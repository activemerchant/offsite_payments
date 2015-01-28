require 'test_helper'

class RazorpayTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_notification_method
    assert_instance_of Razorpay::Notification, Razorpay.notification("razorpay_payment_id=pay_2SQt8mN7tu2MIk")
  end
end
