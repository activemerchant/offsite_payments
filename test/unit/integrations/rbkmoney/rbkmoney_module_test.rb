require 'test_helper'

class RbkmoneyModuleTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_notification_method
    assert_instance_of Rbkmoney::Notification, Rbkmoney.notification('name=cody')
  end
end
