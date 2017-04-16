require 'test_helper'

class RazorpayHelperTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @key_id = fixtures(:razorpay)[:key_id]
    @key_secret = fixtures(:razorpay)[:key_secret]
    @helper = Razorpay::Helper.new('order_id',@key_id, 
      :amount => 50.00,
      :currency => 'INR',
      :credential2=>@key_secret
    )
  end

  def test_basic_helper_fields
    # Note that amount is in paise now
    assert_field 'amount', '5000'
    assert_field 'currency', 'INR'
    assert_field 'key', @key_id
    assert_field 'merchant_order_id', 'order_id'
  end

  def test_customer_fields
    @helper.customer :first_name => 'Abhay', :last_name => 'Rana', :email => 'nemo@razorpay.com', :phone => '1234567890'

    assert_field 'prefill[name]',  'Abhay Rana'
    assert_field 'prefill[email]', 'nemo@razorpay.com'
    assert_field 'prefill[contact]', '1234567890'
  end

  def test_merchant_order_fields
    @helper.country = 'India'
    @helper.account_name = 'Razorpay Inc.'
    @helper.description = 'Super Dev Badge'
    @helper.invoice = 'Invoice #123'

    assert_field 'notes[shop_country]', 'India'
    assert_field 'name', 'Razorpay Inc.'
    assert_field 'description', 'Super Dev Badge'
    assert_field 'notes[invoice]', 'Invoice #123'
  end

  def test_shipping_fields
    @helper.shipping_address :first_name => 'Abhay',
      :last_name =>  'Rana',
      :city =>       'San Francisco',
      :company =>    'Facebook',
      :address1 =>   '1 Hacker Way',
      :address2 =>   'Facebook HQ',
      :state =>      'California',
      :zip =>        '94102',
      :country =>    'USA',
      :phone =>      '1234567890'
    assert_field 'notes[shipping_first_name]', 'Abhay'
    assert_field 'notes[shipping_last_name]',  'Rana'
    assert_field 'notes[shipping_city]',       'San Francisco'
    assert_field 'notes[shipping_company]',    'Facebook'
    assert_field 'notes[shipping_address1]',   '1 Hacker Way'
    assert_field 'notes[shipping_address2]',   'Facebook HQ'
    assert_field 'notes[shipping_state]',      'California'
    assert_field 'notes[shipping_zip]',        '94102'
    assert_field 'notes[shipping_country]',    'US' # This is converted to Country Code internally
    assert_field 'notes[shipping_phone]',   '1234567890'
  end

  def test_url_fields
    @helper.return_url = 'https://checkout.razorpay.com/demo'
    @helper.cancel_return_url = 'https://checkout.razorpay.com/demo/cancel'

    assert_field 'url[callback]', 'https://checkout.razorpay.com/demo'
    assert_field 'url[cancel]', 'https://checkout.razorpay.com/demo/cancel'
  end

  def test_signature
    @helper.sign_fields
    assert_field 'signature', '2dbc139e4033f21c847590bc3095f3f397b88b43'
  end
end
