require 'test_helper'

class MercadoPagoTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_notification_method
    assert_instance_of MercadoPago::Notification, MercadoPago.notification('{}')
  end

end
