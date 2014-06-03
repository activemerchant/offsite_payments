require 'test_helper'

class RemoteDirecPayTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @helper = DirecPay::Helper.new('#1234', fixtures(:direc_pay)[:mid], :amount => 500, :currency => 'INR')
    @notification = DirecPay::Notification.new('test=dummy-value')
  end

  def tear_down
    OffsitePayments.mode = :test
  end

  def test_return_is_always_acknowledged
    assert_equal "https://test.direcpay.com/direcpay/secure/dpMerchantTransaction.jsp", DirecPay.service_url
    assert_nothing_raised do
      assert_equal true, @notification.acknowledge
    end
  end

end
