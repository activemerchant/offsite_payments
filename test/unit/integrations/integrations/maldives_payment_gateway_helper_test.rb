require 'test_helper'

class MaldivesPaymentGatewayHelperTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @helper = MaldivesPaymentGateway::Helper.new('order-500','cody@example.com', :amount => 5.00, :currency => 'MVR', :response_url => 'http://localhost',
                                                  :merchant_id => '7796090001009', :password => 'orange', :acquirer_id => '407387', :currency_exponent => '2')  end

  def test_basic_helper_fields
    assert_field 'OrderID', 'order-500'
    assert_field 'PurchaseCurrency', '462'
    assert_field 'PurchaseAmt', '000000000500'
    assert_field 'Version', '1.0.0'
    assert_field 'Signature', 'YjYzMDc1OWVkMzM4Yjk0MmMyNTgzZDcyMjljNmYxMTMzNjhiZWVkYw=='
    assert_field 'AcqID', '407387'
    assert_field 'MerId', '7796090001009'
    assert_field 'SignatureMethod', 'SHA1'
    assert_field 'MerRespURL', 'http://localhost'
  end

  # def test_customer_fields
  #   @helper.customer :first_name => 'Cody', :last_name => 'Fauser', :email => 'cody@example.com'
  #   assert_field '', 'Cody'
  #   assert_field '', 'Fauser'
  #   assert_field '', 'cody@example.com'
  # end

  # def test_address_mapping
  #   @helper.billing_address :address1 => '1 My Street',
  #                           :address2 => '',
  #                           :city => 'Leeds',
  #                           :state => 'Yorkshire',
  #                           :zip => 'LS2 7EE',
  #                           :country  => 'CA'

  #   assert_field '', '1 My Street'
  #   assert_field '', 'Leeds'
  #   assert_field '', 'Yorkshire'
  #   assert_field '', 'LS2 7EE'
  # end

  # def test_unknown_address_mapping
  #   @helper.billing_address :farm => 'CA'
  #   assert_equal 3, @helper.fields.size
  # end

  # def test_unknown_mapping
  #   assert_nothing_raised do
  #     @helper.company_address :address => '500 Dwemthy Fox Road'
  #   end
  # end

  # def test_setting_invalid_address_field
  #   fields = @helper.fields.dup
  #   @helper.billing_address :street => 'My Street'
  #   assert_equal fields, @helper.fields
  # end
end
