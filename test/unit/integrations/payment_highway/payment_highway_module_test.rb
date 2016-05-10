require 'test_helper'

class PaymentHighwayTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_notification_method
    assert_instance_of PaymentHighway::Notification, PaymentHighway.notification('name=cody')
  end
end
