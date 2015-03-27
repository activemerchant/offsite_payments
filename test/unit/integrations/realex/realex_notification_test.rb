require 'test_helper'

class RealexNotificationTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @notification = Realex::Notification.new(http_raw_data, :credential3 => 'shared-secret')
  end

  def test_accessors
    assert @notification.verified?
    assert @notification.complete?
    assert @notification.acknowledge
    assert_equal "Completed", @notification.status
    assert_equal 50.0, @notification.gross
    assert_equal "USD", @notification.currency
  end

  def test_compositions
    assert_equal Money.new(5000, 'USD'), @notification.amount
  end

  private

  def http_raw_data
    "MERCHANT_ID=thestore&ACCOUNT=internet&ORDER_ID=ORD453-11&TIMESTAMP=20130814122239&AMOUNT=5000&X-CURRENCY=USD&SHA1HASH=dbd337bb359fa40312a7f7140ef72139cec7dace&RESULT=00&AUTHCODE=123420&MESSAGE=AUTHCODE=123420&PASREF=13649024563820&AVSPOSTCODERESULT=U&AVSADDRESSRESULT=U&CVNRESULT=M&BATCHID=870"
  end

end
