require 'test_helper'

class MercadoPagoTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_notification_method
    Net::HTTP.expects(:get_response).returns(stub(body: "{}"))
    assert_instance_of MercadoPago::Notification, MercadoPago.notification('collection_id=805289315')
  end

end
