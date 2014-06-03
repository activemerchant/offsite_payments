require 'test_helper'

class IntegrationsTest < Test::Unit::TestCase
  def setup
    OffsitePayments.mode = :test
  end

  def teardown
    OffsitePayments.mode = :test
  end

  def test_should_return_an_integration_by_name
    chronopay = OffsitePayments.integration(:chronopay)

    assert_equal Integrations::Chronopay, chronopay
    assert_instance_of Integrations::Chronopay::Notification, chronopay.notification('name=cody')
  end

  def test_should_set_modes
    OffsitePayments.mode = :test
    assert_equal :test, OffsitePayments.mode

    OffsitePayments.mode = :production
    assert_equal :production, OffsitePayments.mode

    OffsitePayments.mode             = :development
    assert_equal :development, OffsitePayments.mode
  end
end
