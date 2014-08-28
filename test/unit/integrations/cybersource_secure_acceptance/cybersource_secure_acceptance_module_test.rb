require 'test_helper'

class CybersourceSecureAcceptanceModuleTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_notification_method
    assert_instance_of CybersourceSecureAcceptance::Notification, CybersourceSecureAcceptance.notification('name=cody')
  end
end
