require 'test_helper'

class QuickpayV10ModuleTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_notification_method
    assert_instance_of QuickpayV10::Notification, QuickpayV10.notification('{}', {})
  end
end
