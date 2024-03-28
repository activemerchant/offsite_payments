require 'test_helper'

class RealexOffsiteHelperTest < Test::Unit::TestCase
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
    OffsitePayments::Integrations::RealexOffsite::Helper.application_id = 'Shopify'
    @helper = RealexOffsite::Helper.new('order-500', 'merchant-1234', order_attributes)
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
                     :phone => '(555)555-5555'

    assert_field 'HPP_CUSTOMER_EMAIL', 'cody@example.com'
  end

  def test_raises_invalid_customer
    assert_raise ArgumentError do
      @helper.customer(:email => 'cody@example')
    end
    assert_nothing_raised ArgumentError do
      @helper.customer :phone => '(000)000-0000'
    end
    assert_field 'HPP_CUSTOMER_PHONENUMBER_MOBILE', '0|0'
  end

  def test_phone_formatting
    @helper.customer :phone => '+48 12 345 67 89'
                     
    @helper.billing_address :country => 'PL'

    assert_field 'HPP_CUSTOMER_PHONENUMBER_MOBILE', '48|123456789'
  end

  def test_phone_formatting_when_no_country_specified
    @helper.customer :phone => '123-456-789'

    assert_field 'HPP_CUSTOMER_PHONENUMBER_MOBILE', '0|123456789'
  end

  def test_phone_formatting_for_italy_when_leading_zero_exists
    @helper.customer :phone => '06 123 4567'

    @helper.billing_address :country => 'IT'

    assert_field 'HPP_CUSTOMER_PHONENUMBER_MOBILE', '39|061234567'
  end

  def test_phone_formatting_for_italy_when_leading_zero_does_not_exist
    @helper.customer :phone => '330 1234567'

    @helper.billing_address :country => 'IT'

    assert_field 'HPP_CUSTOMER_PHONENUMBER_MOBILE', '39|3301234567'
  end

  def test_phone_formatting_for_singapore_when_no_country_code_is_given
    @helper.customer :phone => '0 6500 0000'

    @helper.billing_address :country => 'SG'

    assert_field 'HPP_CUSTOMER_PHONENUMBER_MOBILE', '65|65000000'
  end

  def test_phone_formatting_for_singapore_when_country_code_is_given
    @helper.customer :phone => '65 6500 0000'

    @helper.billing_address :country => 'SG'

    assert_field 'HPP_CUSTOMER_PHONENUMBER_MOBILE', '65|65000000'
  end

  def test_fixing_phone_calling_code
    @helper.customer :phone => '+84 12 345 67 89'
                     
    @helper.billing_address :country => 'PL'

    assert_field 'HPP_CUSTOMER_PHONENUMBER_MOBILE', '48|123456789'
  end

  def test_address_mapping
    @helper.billing_address :address1 => '1 My Streetº',
                            :address2 => 'Apt. 1',
                            :address3 => 'Entrance B',
                            :city => 'Leeds',
                            :state => 'Newfoundland',
                            :zip => 'LS2 7EE',
                            :country  => 'CA'

    assert_field 'HPP_BILLING_POSTALCODE', 'LS2 7EE'
    assert_field 'HPP_BILLING_COUNTRY', '124'
    assert_field 'HPP_BILLING_STREET1', '1 My Streetº'
    assert_field 'HPP_BILLING_STREET2', 'Apt. 1'
    assert_field 'HPP_BILLING_STREET3', 'Entrance B'
    assert_field 'HPP_BILLING_CITY', 'Leeds'
    assert_field 'HPP_BILLING_STATE', 'NL'
    assert_field 'BILLING_CODE', 'LS2 7EE|1 My Street'
  end

  def test_address_mapping_gb
    @helper.billing_address :address1 => '1 My Street',
                            :address2 => 'Apt. 1',
                            :address3 => 'Entrance B',
                            :city => 'Leeds',
                            :zip => 'LS2 7EE',
                            :country  => 'GB'

    assert_field 'BILLING_CODE', '27|1'
  end

  def test_es_billing_code
    @helper.billing_address :address1 => '1 My Street',
                            :address2 => 'Apt. 1',
                            :address3 => 'Entrance B',
                            :city => 'Leeds',
                            :zip => 'LS2 7EE',
                            :country  => 'ES'

    assert_field 'BILLING_CODE', nil
  end

  def test_us_country_state
    @helper.billing_address :address1 => '1 My Street',
                            :address2 => 'Apt. 1',
                            :address3 => 'Entrance B',
                            :city => 'Pasadena',
                            :zip => 'LS2 7EE',
                            :country  => 'United States',
                            :state => 'California'

    assert_field 'HPP_BILLING_STATE', 'CA'
    assert_field 'HPP_BILLING_COUNTRY', '840'
  end

  def test_canada_country_state
    @helper.billing_address :address1 => '1 My Street',
                            :address2 => 'Apt. 1',
                            :address3 => 'Entrance B',
                            :city => 'Pasadena',
                            :zip => 'LS2 7EE',
                            :country  => 'Canada',
                            :state => 'Newfoundland'

    assert_field 'HPP_BILLING_STATE', 'NL'
    assert_field 'HPP_BILLING_COUNTRY', '124'
  end

  def test_raises_invalid_billing_address
    assert_raise ArgumentError do
      @helper.billing_address :address1  => '1 My Street▓'
    end
    assert_raise ArgumentError do
      @helper.billing_address :address2  => 'My Street (2'
    end
    assert_raise ArgumentError do
      @helper.billing_address :address2  => 'My Street )2'
    end
    assert_raise ArgumentError do
      @helper.billing_address :address1  => 'Lorem Ipsum is simply dummy text for testing length'
    end
    assert_raise ArgumentError do
      @helper.billing_address :city  => 'Lorem Ipsum is simply dummy text for testing length'
    end
    assert_raise ArgumentError do
      @helper.billing_address :zip  => 'LS2 7EE | 555'
    end
    assert_raise ArgumentError do
      @helper.billing_address :country  => 'ZZ'
    end
    assert_raise ArgumentError do
      @helper.billing_address :state  => '8888',
                              :country  => 'Canada'
    end
    assert_raise ArgumentError do
      @helper.billing_address :state  => '8888',
                              :country  => 'United States'
    end
    assert_nothing_raised ArgumentError do
      @helper.billing_address :state  => '8888',
                              :country  => 'United Kingdom'
    end
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

    assert_field 'HPP_SHIPPING_POSTALCODE', 'LS2 7E1'
    assert_field 'HPP_SHIPPING_COUNTRY', '826'
    assert_field 'HPP_SHIPPING_STREET1', '1 My Street'
    assert_field 'HPP_SHIPPING_STREET2', 'Apt. 1'
    assert_field 'HPP_SHIPPING_STREET3', 'Entrance B'
    assert_field 'HPP_SHIPPING_CITY', 'London'
    assert_field 'HPP_SHIPPING_STATE', nil
    assert_field 'SHIPPING_CODE', 'LS2 7E1'
  end

  def test_shipping_us_country_state
    @helper.shipping_address :address1 => '1 My Street',
                             :address2 => 'Apt. 1',
                             :address3 => 'Entrance B',
                             :city => 'Pasadena',
                             :zip => 'LS2 7EE',
                             :country  => 'United States',
                             :state => 'California'

    assert_field 'HPP_SHIPPING_STATE', 'CA'
    assert_field 'HPP_SHIPPING_COUNTRY', '840'
  end

  def test_shipping_canada_country_state
    @helper.shipping_address :address1 => '1 My Street',
                             :address2 => 'Apt. 1',
                             :address3 => 'Entrance B',
                             :city => 'Pasadena',
                             :zip => 'LS2 7EE',
                             :country  => 'Canada',
                             :state => 'Newfoundland'

    assert_field 'HPP_SHIPPING_STATE', 'NL'
    assert_field 'HPP_SHIPPING_COUNTRY', '124'
  end

  def test_raises_invalid_shipping_address
    assert_raise ArgumentError do
      @helper.shipping_address :address1  => '1 My Street▓'
    end
    assert_raise ArgumentError do
      @helper.shipping_address :city  => 'Lorem Ipsum is simply dummy text for testing length'
    end
    assert_raise ArgumentError do
      @helper.shipping_address :zip  => 'LS2 7EE | 555'
    end
    assert_raise ArgumentError do
      @helper.shipping_address :country  => 'ZZ'
    end
    assert_raise ArgumentError do
      @helper.shipping_address :state  => '8888',
                               :country  => 'Canada'
    end
    assert_raise ArgumentError do
      @helper.shipping_address :state  => '8888',
                               :country  => 'United States'
    end
    assert_nothing_raised ArgumentError do
      @helper.shipping_address :state  => '8888',
                               :country  => 'United Kingdom'
    end
  end

  def test_address_match_indicator
    @helper.billing_address :address1 => '1 My Street',
                            :address2 => 'Apt. 1',
                            :address3 => 'Entrance B',
                            :city => 'Leeds',
                            :state => 'Yorkshire',
                            :zip => 'LS2 7E1',
                            :country  => 'United Kingdom'

    @helper.addresses_match true

    assert_field 'HPP_ADDRESS_MATCH_INDICATOR', 'TRUE'

    assert_field 'HPP_SHIPPING_POSTALCODE', 'LS2 7E1'
    assert_field 'HPP_SHIPPING_COUNTRY', '826'
    assert_field 'HPP_SHIPPING_STREET1', '1 My Street'
    assert_field 'HPP_SHIPPING_STREET2', 'Apt. 1'
    assert_field 'HPP_SHIPPING_STREET3', 'Entrance B'
    assert_field 'HPP_SHIPPING_CITY', 'Leeds'
    assert_field 'HPP_SHIPPING_STATE', nil
  end

  def test_address_match_indicator_false
    @helper.addresses_match false

    assert_field 'HPP_ADDRESS_MATCH_INDICATOR', 'FALSE'
  end

  def test_address_match_indicator_not_sent
    assert_field 'HPP_ADDRESS_MATCH_INDICATOR', nil
  end

  def test_does_not_require_shipping
    @helper.addresses_match true
    @helper.shipping_address :name => 'Testing Tester',
                             :address1 => '1 My Street',
                             :address2 => 'Apt. 1',
                             :address3 => 'Entrance B',
                             :city => 'London',
                             :state => 'Whales',
                             :zip => 'LS2 7E1',
                             :country  => 'GB'
    @helper.require_shipping false

    assert_field 'HPP_ADDRESS_MATCH_INDICATOR', nil
    assert_field 'HPP_SHIPPING_POSTALCODE', nil
    assert_field 'HPP_SHIPPING_COUNTRY', nil
    assert_field 'HPP_SHIPPING_STREET1', nil
    assert_field 'HPP_SHIPPING_STREET2', nil
    assert_field 'HPP_SHIPPING_STREET3', nil
    assert_field 'HPP_SHIPPING_CITY', nil
    assert_field 'HPP_SHIPPING_STATE', nil
  end

  def test_comment1_equals_application_id
    assert_field 'COMMENT1', 'Shopify'
  end

  def test_comment
    @helper.comment 'This is my fancy comment'

    assert_field 'COMMENT2', 'This is my fancy comment'
  end

  def test_format_amount_as_float
    amount_gbp = @helper.format_amount_as_float(929, 'GBP')
    assert_in_delta 9.29, amount_gbp, 0.001

    amount_bhd = @helper.format_amount_as_float(929, 'BHD')
    assert_in_delta 0.929, amount_bhd, 0.001
  end

  def test_format_amount
    amount_gbp = @helper.format_amount('9.29', 'GBP')
    assert_equal amount_gbp, 929

    amount_bhd = @helper.format_amount(0.929, 'BHD')
    assert_equal amount_bhd, 929
  end
end
