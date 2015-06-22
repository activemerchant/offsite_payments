require 'test_helper'

class MaldivesPaymentGatewayTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_notification_method
    assert_instance_of MaldivesPaymentGateway::Notification, MaldivesPaymentGateway.notification('name=cody')
  end
end
