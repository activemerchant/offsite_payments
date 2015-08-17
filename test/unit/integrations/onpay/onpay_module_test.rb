require 'test_helper'

class OnpayModuleTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_helper_method
    assert_instance_of Onpay::Helper, Onpay.helper(123, 'test')
  end

  def test_notification_method
    assert_instance_of Onpay::Notification, Onpay.notification('{}')
  end

end
