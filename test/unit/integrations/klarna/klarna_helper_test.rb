require 'test_helper'

class KlarnaHelperTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @order_id = 1
    @credential1 = "Example Merchant ID"
    @options = {
      :amount           => Money.from_amount(0.10, 'SEK'),
      :currency         => 'SEK',
      :country          => 'SE',
      :account_name     => 'Example Shop Name',
      :credential2      => 'Example shared secret',
      :test             => false,
      :checkout_token   => 'abc123'
    }

    @helper = Klarna::Helper.new(@order_id, @credential1, @options)
  end

  def test_test_mode_is_always_set
    @helper = Klarna::Helper.new(@order_id, @credential1, @options.merge(:test => true))
    assert_field 'test_mode', 'true'

    OffsitePayments.mode = :not_test
    @helper = Klarna::Helper.new(@order_id, @credential1, @options.merge(:test => false))
    assert_field 'test_mode', 'false'
  ensure
    OffsitePayments.mode = :test
  end

  def test_basic_helper_fields
    assert_field 'purchase_currency', @options[:currency]
    assert_field 'merchant_id', @credential1
    assert_field 'platform_type', @helper.application_id
    assert_field 'checkout_token', @options[:checkout_token]
  end

  def test_customer_fields
    @helper.customer :email => 'email@example.com'

    assert_field 'shipping_address_email', 'email@example.com'
  end

  def test_shipping_fields
    @helper.shipping_address :first_name => 'First name',
                             :last_name  => 'Last name',
                             :city       => 'City',
                             :company    => 'Company',
                             :address1   => 'Street address',
                             :address2   => 'Second floor',
                             :state      => 'State',
                             :country    => 'Country',
                             :zip        => 'A1B 2C3',
                             :phone      => '+1 (555) 555-5555'

    assert_field 'shipping_address_given_name', 'First name'
    assert_field 'shipping_address_family_name', 'Last name'
    assert_field 'shipping_address_street_address', 'Street address, Second floor'
    assert_field 'shipping_address_postal_code', 'A1B 2C3'
    assert_field 'shipping_address_city', 'City'
    assert_field 'shipping_address_country', 'Country'
    assert_field 'shipping_address_phone', '+1 (555) 555-5555'
  end

  def test_billing_fields
    @helper.billing_address :country => 'SE'

    assert_field 'locale', "sv-se"
    assert_field 'purchase_country', 'SE'
  end

  def test_merchant_digest
    @helper = valid_helper

    assert_field 'merchant_digest', "Efs6wr3Fhg4eGfQGMpelqTblLlXBzSCMz9fLUR9Bt74="
  end

  def test_line_item
    item = example_line_item
    @helper.line_item(item)

    assert_field 'cart_item-0_type', 'physical'
    assert_field 'cart_item-0_reference', '#1'
    assert_field 'cart_item-0_name', 'example item description'
    assert_field 'cart_item-0_quantity', '1'
    assert_field 'cart_item-0_unit_price', (900 + 100).to_s
    assert_field 'cart_item-0_tax_rate', '1111'
  end

  def test_merchant_uri_fields
    @helper.notify_url('http://example-notify-url')
    @helper.return_url('http://example-return-url.com/?something=else')

    example_cancel_url = "http://example-cancel-url"
    @helper.cancel_return_url("http://example-cancel-url")

    assert_field 'merchant_push_uri', 'http://example-notify-url?order=1'
    assert_field 'merchant_confirmation_uri', 'http://example-return-url.com/?order=1&something=else'
    assert_field 'merchant_terms_uri', example_cancel_url
    assert_field 'merchant_checkout_uri', example_cancel_url
    assert_field 'merchant_base_uri', example_cancel_url
  end

  private

  def example_line_item(order_number = 1)
    {
      :type => 'line item',
      :reference => "##{order_number}",
      :name => 'example item description',
      :quantity => 1,
      :unit_price => 900,
      :discount_rate => nil,
      :tax_amount => 100
    }
  end

  def valid_helper
    helper = Klarna::Helper.new(@order_id, @credential1, @options)

    helper.line_item(example_line_item)
    helper.return_url("http://example-return-url")
    helper.cancel_return_url("http://example-cancel-url")
    helper.billing_address :country => 'SE'
    helper.sign_fields

    helper
  end
end
