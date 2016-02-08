require 'test_helper'

class YandexKassaTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_notification_method
    assert_instance_of YandexKassa::Notification, YandexKassa.notification('name=cody')
  end
end
