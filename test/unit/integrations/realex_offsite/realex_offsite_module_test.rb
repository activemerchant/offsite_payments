require 'test_helper'

class RealexOffsiteModuleTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_helper_method
    assert_instance_of RealexOffsite::Helper, RealexOffsite.helper(123, 'test')
  end

  def test_return_method
    assert_instance_of RealexOffsite::Return, RealexOffsite.return('name=cody', {})
  end

  def test_notification_method
    assert_instance_of RealexOffsite::Notification, RealexOffsite.notification('name=cody')
  end

  def test_test_process_mode
    OffsitePayments.stubs(:mode).returns(:test)
    assert_equal 'https://hpp.sandbox.realexpayments.com/pay', RealexOffsite.service_url
  end

  def test_production_mode
    OffsitePayments.stubs(:mode).returns(:production)
    assert_equal 'https://epage.payandshop.com/epage.cgi', RealexOffsite.service_url
  end

  def test_invalid_mode
    OffsitePayments.stubs(:mode).returns(:zoomin)
    assert_raise(StandardError){ RealexOffsite.service_url }
  end

end
