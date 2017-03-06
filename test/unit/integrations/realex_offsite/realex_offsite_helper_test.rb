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
  end

  def test_customer_mapping
    @helper.customer :first_name => 'Cody', :last_name => 'Fauser', :email => 'cody@example.com', :phone => '(555)555-5555'
    assert_field 'CUST_NUM', 'cody@example.com'
  end

  def test_address_mapping
    @helper.billing_address :address1 => '1 My Street',
                            :address2 => 'Apt. 1',
                            :city => 'Leeds',
                            :state => 'Yorkshire',
                            :zip => 'LS2 7EE',
                            :country  => 'CA'

    assert_field 'BILLING_CODE', '27|1'
    assert_field 'BILLING_CO', 'CA'
  end

  def test_shipping_address
    @helper.shipping_address :name => 'Testing Tester',
                             :address1 => '1 My Street',
                             :address2 => 'Apt. 1',
                             :city => 'London',
                             :state => 'Whales',
                             :zip => 'LS2 7E1',
                             :country  => 'GB'

    assert_field 'SHIPPING_CODE', '271|1'
    assert_field 'SHIPPING_CO', 'GB'
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
