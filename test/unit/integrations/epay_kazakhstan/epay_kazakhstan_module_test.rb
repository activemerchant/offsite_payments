require 'test_helper'

class EpayKazakhstanModuleTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_notification_method
    assert_instance_of EpayKazakhstan::Notification, EpayKazakhstan.notification({'response' => {}})
  end

  def test_configuration_method
    assert_instance_of EpayKazakhstan::Configuration, EpayKazakhstan.configuration
  end
end