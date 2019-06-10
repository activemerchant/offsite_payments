require 'test_helper'

class GlobalPaymentsOffsiteModuleTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_helper_method
    assert_instance_of GlobalPaymentsOffsite::Helper, GlobalPaymentsOffsite.helper(123, 'test')
  end

  def test_return_method
    assert_instance_of GlobalPaymentsOffsite::Return, GlobalPaymentsOffsite.return('name=cody', {})
  end

  def test_notification_method
    assert_instance_of GlobalPaymentsOffsite::Notification, GlobalPaymentsOffsite.notification('name=cody')
  end

  def test_test_process_mode
    OffsitePayments.stubs(:mode).returns(:test)
    assert_equal 'https://hpp.sandbox.realexpayments.com/pay', GlobalPaymentsOffsite.service_url
  end

  def test_production_mode
    OffsitePayments.stubs(:mode).returns(:production)
    assert_equal 'https://epage.payandshop.com/epage.cgi', GlobalPaymentsOffsite.service_url
  end

  def test_invalid_mode
    OffsitePayments.stubs(:mode).returns(:zoomin)
    assert_raise(StandardError){ GlobalPaymentsOffsite.service_url }
  end

end
