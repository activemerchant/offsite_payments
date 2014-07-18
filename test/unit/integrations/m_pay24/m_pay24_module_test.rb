require 'test_helper'

class MPay24Test < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_notification_method
    assert_instance_of MPay24::Notification, MPay24.notification('name=cody')
  end
end
