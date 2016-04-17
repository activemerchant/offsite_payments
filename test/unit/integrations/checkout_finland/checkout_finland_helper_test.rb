# encoding: UTF-8
require 'test_helper'

class CheckoutFinlandHelperTest < Test::Unit::TestCase
  include OffsitePayments::Integrations
  
  def setup
    @helper = CheckoutFinland::Helper.new('1389003386','375917', :amount => 200, :currency => 'EUR', :credential2 => "SAIPPUAKAUPPIAS")
  end
 
  def test_basic_helper_fields
    assert_field 'MERCHANT', '375917'

    assert_field 'AMOUNT', '200'
    assert_field 'STAMP', '1389003386'
  end
  
  def test_customer_fields
    @helper.customer :first_name => 'Tero', :last_name => 'Testaaja', :phone => '0800 552 010', :email => 'support@checkout.fi'
    assert_field 'FIRSTNAME', 'Tero'
    assert_field 'FAMILYNAME', 'Testaaja'
    assert_field 'PHONE', '0800 552 010'
    assert_field 'EMAIL', 'support@checkout.fi'
  end

  def test_address_mapping
    @helper.billing_address :address1 => 'Testikatu 1 A 10',
                            :city => 'Helsinki',
                            :zip => '00100',
                            :country  => 'FIN'
   
    assert_field 'ADDRESS', 'Testikatu 1 A 10'
    assert_field 'POSTOFFICE', 'Helsinki'
    assert_field 'POSTCODE', '00100'
    assert_field 'COUNTRY', 'FIN'
  end

  def test_authcode_generation
    @helper.customer :first_name => 'Tero', :last_name => 'Testaaja', :phone => '0800 552 010', :email => 'support@checkout.fi'
    @helper.billing_address :address1 => 'Testikatu 1 A 10',
                            :city => 'Helsinki',
                            :zip => '00100',
                            :country  => 'FIN'

    @helper.reference = "474738238"
    @helper.language = "FI"
    @helper.content = "1"
    @helper.delivery_date = "20140110"
    @helper.description = "Some items"

    @helper.notify_url = "http://www.example.com/notify"
    @helper.reject_url = "http://www.example.com/reject"
    @helper.return_url = "http://www.example.com/return"
    @helper.cancel_return_url = "http://www.example.com/cancel"

    assert_equal @helper.generate_md5string, "0968BCF2A747F4A9118A889C8EC5CDA3"

  end
  
  def test_unknown_address_mapping
    @helper.billing_address :farm => 'CA'
    assert_equal 8, @helper.fields.size
  end

  def test_unknown_mapping
    assert_nothing_raised do
      @helper.company_address :address => '500 Dwemthy Fox Road'
    end
  end
  
  def test_setting_invalid_address_field
    fields = @helper.fields.dup
    @helper.billing_address :street => 'My Street'
    assert_equal fields, @helper.fields
  end

end
