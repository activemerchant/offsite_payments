require 'test_helper'

class GlobalPaymentsHelperTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def credentials
    {
      :credential2 => 'merchant-1234-sub-account',
      :credential3 => 'shared-secret'
    }
  end

  def order_attributes
    {:amount => '9.99', :currency => 'GBP'}.merge(credentials)
  end

  def setup
    @helper = GlobalPaymentsOffsite::Helper.new('order-500', 'merchant-1234', order_attributes)
  end

  def teardown
    OffsitePayments.mode = :test
  end

  def test_required_helper_fields
    assert_field 'MERCHANT_ID', 'merchant-1234'
    assert_field 'ACCOUNT', 'merchant-1234-sub-account'
    assert_field 'CURRENCY', 'GBP'
    assert_field 'AMOUNT', '999'
    assert_field 'CHECKOUT_ID', 'order-500'
    assert_field 'ORDER_ID', 'order-500' + @helper.fields["TIMESTAMP"]
  end

  def test_default_helper_fields
    assert_field 'AUTO_SETTLE_FLAG', '1'
    assert_field 'RETURN_TSS', '1'
    assert_field 'HPP_VERSION', '2'
  end

  def test_customer_mapping
    @helper.customer :first_name => 'Cody',
                     :last_name => 'Fauser',
                     :email => 'cody@example.com',
                     :phone => '(555)555-5555',
                     :work_phone => '(555)555-6666'

    assert_field 'HPP_CUSTOMER_EMAIL', 'cody@example.com'
    assert_field 'HPP_CUSTOMER_PHONENUMBER_HOME', '(555)555-5555'
    assert_field 'HPP_CUSTOMER_PHONENUMBER_WORK', '(555)555-6666'
  end

  def test_address_mapping
    @helper.billing_address :address1 => '1 My Street',
                            :address2 => 'Apt. 1',
                            :address3 => 'Entrance B',
                            :city => 'Leeds',
                            :state => 'Yorkshire',
                            :zip => 'LS2 7EE',
                            :country  => 'CA'

    assert_field 'HPP_BILLING_POSTALCODE', '27|1'
    assert_field 'HPP_BILLING_COUNTRY', '124'
    assert_field 'HPP_BILLING_STREET1', '1 My Street'
    assert_field 'HPP_BILLING_STREET2', 'Apt. 1'
    assert_field 'HPP_BILLING_STREET3', 'Entrance B'
    assert_field 'HPP_BILLING_CITY', 'Leeds'
    assert_field 'HPP_BILLING_STATE', 'Yorkshire'
  end

  def test_shipping_address
    @helper.shipping_address :name => 'Testing Tester',
                             :address1 => '1 My Street',
                             :address2 => 'Apt. 1',
                             :address3 => 'Entrance B',
                             :city => 'London',
                             :state => 'Whales',
                             :zip => 'LS2 7E1',
                             :country  => 'GB'

    assert_field 'HPP_SHIPPING_POSTALCODE', '271|1'
    assert_field 'HPP_SHIPPING_COUNTRY', '826'
    assert_field 'HPP_SHIPPING_STREET1', '1 My Street'
    assert_field 'HPP_SHIPPING_STREET2', 'Apt. 1'
    assert_field 'HPP_SHIPPING_STREET3', 'Entrance B'
    assert_field 'HPP_SHIPPING_CITY', 'London'
    assert_field 'HPP_SHIPPING_STATE', 'Whales'
  end

  def test_address_match_indicator
    @helper.addresses_match = true

    assert_field 'HPP_ADDRESS_MATCH_INDICATOR', 'Y'
  end

  def test_address_match_indicator_false
    @helper.addresses_match = false

    assert_field 'HPP_ADDRESS_MATCH_INDICATOR', 'N'
  end

  def test_address_match_indicator_not_sent
    assert_field 'HPP_ADDRESS_MATCH_INDICATOR', nil
  end

  def test_format_amount_as_float
    amount_gbp = @helper.format_amount_as_float(929, 'GBP')
    assert_in_delta amount_gbp, 9.29, 0.00

    amount_bhd = @helper.format_amount_as_float(929, 'BHD')
    assert_in_delta amount_bhd, 0.929, 0.00
  end

  def test_format_amount
    amount_gbp = @helper.format_amount('9.29', 'GBP')
    assert_equal amount_gbp, 929

    amount_bhd = @helper.format_amount(0.929, 'BHD')
    assert_equal amount_bhd, 929
  end
end
