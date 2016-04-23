require 'test_helper'

class YandexMoneyModuleTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_notification_method
    assert_instance_of YandexMoney::Notification, YandexMoney.notification('name=cody')
  end
end
