require 'test_helper'

class PaytmHelperTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @order = 'order-500'
    @account = 'zork'
    @key = 'kbzk1DSbJiV_O3p5'
    @credential3 = '123456789'
    @credential4 = 'abcdefghijk'
    @amount = 123.45
    @currency = 'USD'
    @test = false
    @country = 'US'
    @account_name = 'Widgets Inc'
    @forward_url = "https://secure.paytm.in/oltp-web/genericPT?MID=zork"
    @options = {:amount => @amount,
                :currency => @currency,
                :test => @test,
                :credential2 => @key,
                :credential3 => @credential3,
                :credential4 => @credential4,
                :country => @country,
                :account_name => @account_name,
                :forward_url => @forward_url}
    @helper = Paytm::Helper.new(@order, @account, @options)
  end

  def test_credential_based_url
    assert_equal @forward_url, @helper.credential_based_url
  end

  def test_core_fields
    @helper.description 'Box of Red Wine'
    @helper.invoice 'Invoice #1A'

    assert_field 'x_account_id', @account
    assert_field 'x_credential3', @credential3
    assert_field 'x_credential4', @credential4
    assert_field 'x_currency', @currency
    assert_field 'x_amount', '123.45'
    assert_field 'x_reference', @order
    assert_field 'x_description', 'Box of Red Wine'
    assert_field 'x_invoice', 'Invoice #1A'
    assert_field 'x_test', @test.to_s
  end

  def test_empty_credential_field_not_present_in_request
    @options[:credential3] = ''
    @options[:credential4] = ''
    @helper = Paytm::Helper.new(@order, @account, @options)

    assert_field 'x_credential3', nil
    assert_field 'x_credential4', nil
  end

  def test_special_currency_formatting
    @options[:currency] = 'COU'
    @helper = Paytm::Helper.new(@order, @account, @options)

    assert_field 'x_currency', 'COU'
    assert_field 'x_amount', '123.4500'
  end

  def test_customer_fields
    @helper.customer :email      => 'cody@example.com',
                     :phone      => '(613) 456-7890'

    assert_field 'x_customer_email',      'cody@example.com'
    assert_field 'x_customer_phone',      '(613) 456-7890'
  end

  def test_url_fields
    @helper.notify_url 'https://zork.com/notify'
    @helper.return_url 'https://zork.com/return'
    @helper.cancel_return_url 'https://zork.com/cancel'

    assert_field 'x_url_callback', 'https://zork.com/notify'
    assert_field 'x_url_complete', 'https://zork.com/return'
    assert_field 'x_url_cancel', 'https://zork.com/cancel'
  end

  def test_signature
    expected_signature = Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::SHA256.new, @key, 'x_account_idzorkx_amount123.45x_credential3123456789x_credential4abcdefghijkx_currencyUSDx_referenceorder-500x_testfalse')).delete("\n")
    @helper.sign_fields

    assert_field 'x_signature', expected_signature
  end

  def test_signature_when_some_credentials_are_not_defined
    @options[:credential3] = ''
    @options[:credential4] = ''
    @helper = Paytm::Helper.new(@order, @account, @options)
    expected_signature = Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::SHA256.new, @key, 'x_account_idzorkx_amount123.45x_currencyUSDx_referenceorder-500x_testfalse')).delete("\n")
    @helper.sign_fields

    assert_field 'x_signature', expected_signature
  end
end
