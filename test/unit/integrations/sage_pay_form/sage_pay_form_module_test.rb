require 'test_helper'

class SagePayFormModuleTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_return_method
    assert_instance_of SagePayForm::Return, SagePayForm.return('name=cody', {})
  end

  def test_production_mode
    OffsitePayments.mode = :production
    assert_equal 'https://live.sagepay.com/gateway/service/vspform-register.vsp', SagePayForm.service_url
  ensure
    OffsitePayments.mode = :test
  end

  def test_test_mode
    OffsitePayments.mode = :test
    assert_equal 'https://test.sagepay.com/gateway/service/vspform-register.vsp', SagePayForm.service_url
  end

  def test_simulate_mode
    OffsitePayments.mode = :simulate
    assert_equal 'https://test.sagepay.com/Simulator/VSPFormGateway.asp', SagePayForm.service_url
  ensure
    OffsitePayments.mode = :test
  end

  def test_invalid_mode
    OffsitePayments.mode = :zoomin
    assert_raise(StandardError){ SagePayForm.service_url }
  ensure
    OffsitePayments.mode = :test
  end

end
