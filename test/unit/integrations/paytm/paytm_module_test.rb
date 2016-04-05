require 'test_helper'

class PaytmModuleTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_notification
    assert_instance_of Paytm::Notification, Paytm.notification('name=zork')
  end

  def test_return
    assert_instance_of Paytm::Return, Paytm.return('name=zork')
  end

  def test_sign
    expected = Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::SHA256.new, 'zork', 'a1b2')).delete("\n")
    assert_equal expected, Paytm.sign({:b => '2', :a => '1'}, 'zork')
  end

end
