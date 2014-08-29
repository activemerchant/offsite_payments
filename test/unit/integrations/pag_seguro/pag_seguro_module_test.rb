require 'test_helper'

class PagSeguroModuleTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_notification_method
    Net::HTTP.expects(:get_response).returns(stub(code: "200", body: "<xml></xml>"))
    assert_instance_of PagSeguro::Notification, PagSeguro.notification('notificationCode=1234')
  end

  def test_return_method
    assert_instance_of OffsitePayments::Return, PagSeguro.return('{"name":"cody"}', {})
  end

end
