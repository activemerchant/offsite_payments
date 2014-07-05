require 'test_helper'

class CoinbaseModuleTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_notification_method
    assert_instance_of Coinbase::Notification, Coinbase.notification('{"name":"cody"}')
  end
end
