require 'test_helper'

class Ipay88ModuleTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_return_method
    assert_instance_of Ipay88::Return, Ipay88.return('name=cody')
  end

  def test_notification_method
    assert_instance_of Ipay88::Notification, Ipay88.notification('name=cody')
  end

  def test_service_url
    assert_equal "https://payment.ipay88.com.my/epayment/entry.asp", Ipay88.service_url
  end

  def test_requery_url
    assert_equal "https://payment.ipay88.com.my/epayment/enquiry.asp", Ipay88.requery_url
  end
end
