require 'test_helper'

class PaysbuyModuleTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_notification_method
    assert_instance_of Paysbuy::Notification, Paysbuy.notification('name=cody')
  end
end
