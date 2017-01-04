require 'test_helper'

class SwipeGatewayTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_notification_method
    assert_instance_of SwipeGateway::Notification, SwipeGateway.notification('{"name":"cody"}')
  end
end
