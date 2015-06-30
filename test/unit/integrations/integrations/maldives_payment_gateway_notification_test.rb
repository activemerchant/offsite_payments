require 'test_helper'

class MaldivesPaymentGatewayNotificationTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @maldives_payment_gateway = MaldivesPaymentGateway::Notification.new(http_raw_data)
  end

  def test_accessors
    assert @maldives_payment_gateway.transaction_approved?
    assert_equal "1", @maldives_payment_gateway.reason_code
    assert_equal "Transaction is approved.", @maldives_payment_gateway.reason_description
    assert_equal "2362129422091", @maldives_payment_gateway.reference_no
    assert_equal "7CxOGTzwdIB1CJpf12PgVTEoTkI=", @maldives_payment_gateway.signature
    # assert @maldives_payment_gateway.test?
  end



  # Replace with real successful acknowledgement code
  def test_acknowledgement
    assert_equal true, @maldives_payment_gateway.acknowledge('7796090001009', '407387', 'MPGORDID01154321', 'orange')
  end


  private
  def http_raw_data
    <<-RESP
MerID: 7796090001009
AcqID: 407387
OrderID: MPGORDID01154321
ResponseCode: 1
ReasonCode: 1
ReasonCodeDesc: Transaction is approved.
ReferenceNo: 2362129422091
PaddedCardNo: XXXXXXXXXXXX3955
AuthCode: 189477
Signature: 7CxOGTzwdIB1CJpf12PgVTEoTkI=
SignatureMethod: SHA1
RESP
  end
end
