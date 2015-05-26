require 'test_helper'

class PayeerTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_notification_method
    assert_instance_of Payeer::Notification, Payeer.notification('name=cody')
  end
end
