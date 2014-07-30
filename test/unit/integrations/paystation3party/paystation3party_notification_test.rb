require 'test_helper'

class Paystation3partyNotificationTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  #def setup
  #end

  def test_postback
    
    success = {"PaystationPaymentVerification"=>{"ec"=>"0",
                                                  "em"=>"0. No Error - Transaction Successful",
                                                  "ti"=>"234",
                                                  "TransactionID"=>"234",
                                                  "ct"=>"dinersclub",
                                                  "merchant_ref"=>"324234",
                                                  "MerchantReference"=>"324234",
                                                  "tm"=>"T",
                                                  "MerchantSession"=>"ew123",
                                                  "PurchaseAmount"=>"123"},
                  "postback"=>"yes"}
    
    notification = OffsitePayments::Integrations::Paystation3party::Notification.new(success)
    assert notification.complete?
    
    success = {"PaystationPaymentVerification"=>{"ec"=>"91",
                                                  "em"=>"An error message",
                                                  "ti"=>"234",
                                                  "TransactionID"=>"234",
                                                  "ct"=>"dinersclub",
                                                  "merchant_ref"=>"324234",
                                                  "MerchantReference"=>"324234",
                                                  "tm"=>"T",
                                                  "MerchantSession"=>"ew123",
                                                  "PurchaseAmount"=>"123"},
                  "postback"=>"yes"}
    
    notification = OffsitePayments::Integrations::Paystation3party::Notification.new(success)    
    assert !notification.complete?
  end
=begin
  def test_compositions
    assert_equal Money.new(398750, 'DKK'), @epay.amount
  end

  def test_acknowledgement
    assert @epay.acknowledge
  end

  def test_failed_acknnowledgement
    @epay = Epay::Notification.new(http_raw_data, :credential3 => "badmd5string")
    assert !@epay.acknowledge
  end

  def test_generate_md5string
    assert_equal "1957225218913939875020820120403144203453903XXXXXX9862secretmd5",
                 @epay.generate_md5string
  end

  def test_generate_md5hash
    assert_equal "6f81086c474f03af80ef894e48f81f99", @epay.generate_md5hash
  end

  def test_respond_to_acknowledge
    assert @epay.respond_to?(:acknowledge)
  end

  private
  def http_raw_data
    "language=1&txnid=9572252&orderid=189139&amount=398750&currency=208&date=20120403&time=1442&txnfee=0&paymenttype=3&cardno=453903XXXXXX9862&hash=6f81086c474f03af80ef894e48f81f99"
  end
  
=end
end
