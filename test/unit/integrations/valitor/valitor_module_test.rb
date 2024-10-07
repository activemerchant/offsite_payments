require 'test_helper'

class ValitorModuleTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_notification_method
    notification = Valitor.notification('Country=USA', :credential2 => 'password')
    assert_instance_of Valitor::Notification, notification
    assert_equal 'password', notification.instance_eval{@options}[:credential2]
    assert_equal 'USA', notification.customer_country
    assert notification.test?

    OffsitePayments.mode = :production
    assert !Valitor.notification('Country=USA', :credential2 => 'password').test?
  ensure
    OffsitePayments.mode = :test
  end

  def test_return_method
    ret = Valitor.return('Country=USA', :credential2 => 'password')
    assert_instance_of Valitor::Return, ret
    assert_equal 'password', ret.instance_eval{@options}[:credential2]
    assert_equal 'USA', ret.customer_country
    assert ret.test?

    OffsitePayments.mode = :production
    assert !Valitor.return('Country=USA', :credential2 => 'password').test?
  ensure
    OffsitePayments.mode = :test
  end

  def test_service_url
    assert_equal "https://paymentweb.uat.valitor.is/", Valitor.service_url
    OffsitePayments.mode = :production
    assert_equal "https://paymentweb.valitor.is/", Valitor.service_url
  ensure
    OffsitePayments.mode = :test
  end
end
