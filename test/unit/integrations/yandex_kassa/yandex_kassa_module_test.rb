require 'test_helper'

class YandexKassaTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_notification_method
    assert_instance_of YandexKassa::Notification, YandexKassa.notification('name=cody')
  end

  def test_test_mode
    OffsitePayments.mode = :test
    assert_equal YandexKassa.test_url, YandexKassa.service_url
  end

  def test_production_mode
    OffsitePayments.mode = :production
    assert_equal YandexKassa.production_url, YandexKassa.service_url
  ensure
    OffsitePayments.mode = :test
  end

  def test_invalid_mode
    OffsitePayments.mode = :bro
    assert_raise(StandardError){YandexKassa.service_url}
  ensure
    OffsitePayments.mode = :test
  end
end
