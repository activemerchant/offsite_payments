require 'test_helper'

class MegakassaModuleTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_helper_method
    assert_instance_of Megakassa::Helper, Megakassa.helper(123, 0)
  end

  def test_notification_method
    assert_instance_of Megakassa::Notification, Megakassa.notification('uid=1')
  end

  def test_return_method
    assert_instance_of Megakassa::Return, Megakassa.return('uid=1')
  end

  def test_test_mode
    OffsitePayments.mode = :test
    helper = Megakassa.helper(123, 0)

    assert_equal 'https://megakassa.ru/merchant/', Megakassa.service_url
    assert_equal '1', helper.fields['debug'].to_s
  end

  def test_production_mode
    OffsitePayments.mode = :production
    helper = Megakassa.helper(123, 0)

    assert_equal 'https://megakassa.ru/merchant/', Megakassa.service_url
    assert_equal '', helper.fields['debug'].to_s
  ensure
    OffsitePayments.mode = :test
  end

  def test_invalid_mode
    OffsitePayments.mode = :cool
    assert_raise(StandardError){ Megakassa.service_url }
  ensure
    OffsitePayments.mode = :test
  end
end
