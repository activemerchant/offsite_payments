require 'test_helper'

class Paystation3partyHelperTest < Test::Unit::TestCase
  include OffsitePayments
  #include OffsitePayments::Paystation3party
  
  def setup
    @helper = OffsitePayments::Integrations::Paystation3party::Helper.new('order-500','99999999', options={:amount => 50, :gateway_id=>'CARDPAY'})
    #@helper.md5secret "secretmd5"
    #@helpereturn_url 'http://example.com/ok'
    #@helper.cancel_return_url 'http://example.com/cancel'
    #@helper.notify_url 'http://example.com/notify'
  end
  
  def test_initiate

    assert_raise OffsitePayments::Integrations::Paystation3party::NoGatewaySpecifiedError do
	failed_helper = OffsitePayments::Integrations::Paystation3party::Helper.new('order-500','99999999', options={:amount => 50});

    end 

    assert_raise OffsitePayments::Integrations::Paystation3party::NoAmountSpecifiedError do
        failed_helper = OffsitePayments::Integrations::Paystation3party::Helper.new('order-500','99999999', options={:gateway_id=>'CARDPAY'});

    end
  end


end
