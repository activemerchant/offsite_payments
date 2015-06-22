require 'test_helper'

class MaldivesPaymentGatewayHelperTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @helper = MaldivesPaymentGateway::Helper.new('MPGORDID01154321','cody@example.com', :amount => 12, :currency => 'MVR', :response_url => 'http://localhost',
                                                  :merchant_id => '7796090001009', :password => 'orange', :acquirer_id => '407387', :currency_exponent => '2')  end

  def test_basic_helper_fields
    assert_field 'OrderID', 'MPGORDID01154321'
    assert_field 'PurchaseCurrency', '462'
    assert_field 'PurchaseAmt', '000000001200'
    assert_field 'Version', '1.0.0'
    assert_field 'Signature', 'P4XgdpDnYrM6vtDlOr1DHUE/vkU='
    assert_field 'AcqID', '407387'
    assert_field 'MerId', '7796090001009'
    assert_field 'SignatureMethod', 'SHA1'
    assert_field 'MerRespURL', 'http://localhost'
  end
end
