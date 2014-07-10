require 'test_helper'

class RealexModuleTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_helper_method
    assert_instance_of Realex::Helper, Realex.helper(123, 'test')
  end


  def test_return_method
    assert_instance_of Realex::Return, Realex.return('name=cody', {})
  end

  def test_notification_method
    assert_instance_of Realex::Notification, Realex.notification('name=cody')
  end

  def test_test_process_mode
    OffsitePayments.mode = :test
    assert_equal 'https://hpp.sandbox.realexpayments.com/pay', Realex.service_url
  end

  def test_production_mode
    OffsitePayments.mode = :production
    assert_equal 'https://hpp.realexpayments.com/pay', Realex.service_url
  ensure
    OffsitePayments.mode = :test
  end

  def test_invalid_mode
    OffsitePayments.mode = :zoomin
    assert_raise(StandardError){ Realex.service_url }
  ensure
    OffsitePayments.mode = :test
  end

end
