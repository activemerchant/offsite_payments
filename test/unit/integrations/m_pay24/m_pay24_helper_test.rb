require 'test_helper'
require 'open-uri'
require 'nokogiri'

class MPay24HelperTest < Test::Unit::TestCase
  include OffsitePayments::Integrations
  
  def setup
    @helper = MPay24::Helper.new('order-500','cody@example.com', :amount => '3166', :currency => 'USD')
    @helper.shipping '3.20'
    @helper.tax '20'
  end
 
  def test_basic_helper_fields
    assert_field 'merchantID', 'cody@example.com'
    assert_field 'Price', '3166'
    assert_field 'Tid', 'order-500'
  end
  
  def test_customer_fields
    @helper.customer :first_name => 'Cody', :last_name => 'Fauser', :email => 'cody@example.com', :phone => '+9000'
    assert_field 'Name', 'Cody Fauser'
    assert_field 'Email', 'cody@example.com'
    assert_field 'Phone', '+9000'
  end

  def test_address_mapping
    @helper.billing_address :address1 => '1 My Street',
                            :address2 => '',
                            :city => 'Leeds',
                            :state => 'Yorkshire',
                            :zip => 'LS2 7EE',
                            :country  => 'CA'
   
    assert_field 'Street', '1 My Street'
    assert_field 'City', 'Leeds'
    assert_field 'State', 'Yorkshire'
    assert_field 'Zip', 'LS2 7EE'
  end
  
  def test_unknown_address_mapping
    @helper.billing_address :farm => 'CA'
    assert_equal 5, @helper.fields.size
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

  def test_request_document
    @helper.customer :first_name => 'Cody', :last_name => 'Fauser', :email => 'cody@example.com', :phone => '+9000'
    @helper.billing_address :address1 => '1 My Street',
                            :address2 => '',
                            :city => 'Leeds',
                            :state => 'Yorkshire',
                            :zip => 'LS2 7EE',
                            :country  => 'CA'
    @helper.notify_url 'http://example.com/confirmation'
    @helper.return_url 'http://example.com/success'
    @helper.cancel_return_url 'http://example.com/error'
    schema_document = Nokogiri::XML.parse open("https://www.mpay24.com/schemas/MDXI/v3.0/MDXI.xsd")
    request_document = Nokogiri::XML.parse @helper.generate_request
    Nokogiri::XML::Schema.from_document(schema_document).validate(request_document)
  end
end
