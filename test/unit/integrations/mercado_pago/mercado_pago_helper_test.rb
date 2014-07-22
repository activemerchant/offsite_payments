require 'test_helper'

class MercadoPagoHelperTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @helper = MercadoPago::Helper.new('order-500','1234567890', :credential2 => 'CLIENT_SECRET' , :amount => 500)
  end

  def test_basic_helper_fields
    #http://developers.mercadopago.com/documentacion/autenticacion
    assert_field 'client_id', "1234567890"
    assert_field 'client_secret', "CLIENT_SECRET"

    assert_field 'item_unit_price', '500.00'
    assert_field 'item_quantity', '1'
    assert_field 'external_reference', 'order-500'
  end

  def test_customer_fields
    @helper.customer :first_name => 'Cody', :last_name => 'Fauser', :email => 'cody@example.com', :phone => "+5491122334455"
    assert_field 'payer_name', 'Cody'
    assert_field 'payer_surname', 'Fauser'
    assert_field 'payer_email', 'cody@example.com'
    assert_field 'phone_number', '+5491122334455'
  end

  def test_address_mapping
    @helper.billing_address :address1 => 'Street 123',
                            :zip => '5710'

    assert_field 'payer_street_name', 'Street 123'
    assert_field 'payer_zip_code', '5710'

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
end
