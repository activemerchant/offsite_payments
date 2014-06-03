require 'test_helper'

class ValitorModuleTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_notification_method
    notification = Valitor.notification('Land=USA', :credential2 => 'password')
    assert_instance_of Valitor::Notification, notification
    assert_equal 'password', notification.instance_eval{@options}[:credential2]
    assert_equal 'USA', notification.customer_country
    assert notification.test?

    OffsitePayments.mode = :production
    assert !Valitor.notification('Land=USA', :credential2 => 'password').test?
  ensure
    OffsitePayments.mode = :test
  end

  def test_return_method
    ret = Valitor.return('Land=USA', :credential2 => 'password')
    assert_instance_of Valitor::Return, ret
    assert_equal 'password', ret.instance_eval{@options}[:credential2]
    assert_equal 'USA', ret.customer_country
    assert ret.test?

    OffsitePayments.mode = :production
    assert !Valitor.return('Land=USA', :credential2 => 'password').test?
  ensure
    OffsitePayments.mode = :test
  end

  def test_service_url
    assert_equal "https://testvefverslun.valitor.is/1_1/", Valitor.service_url
    OffsitePayments.mode = :production
    assert_equal "https://vefverslun.valitor.is/1_1/", Valitor.service_url
  ensure
    OffsitePayments.mode = :test
  end
end
