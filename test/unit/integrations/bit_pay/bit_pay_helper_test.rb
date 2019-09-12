require 'test_helper'

class BitPayHelperTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @token_v1 = 'g82hEYhfRkhIlX5HJEqO8w5giRVeyGwsJ1wDPRvx8'
    @token_v2 = '5v2K2rwuWQbnKexiQF9Eu6xdCVg7HFtkFNXarGEq9vLR'
    @invoice_id = '98kui1gJ7FocK41gUaBZxG'
    @helper = BitPay::Helper.new(1234, @token_v1, :amount => 500, :currency => 'USD')
  end

  def test_basic_helper_fields
    assert_field 'orderID', "1234"
    assert_field 'price', "500"
    assert_field 'currency', 'USD'
  end

  def test_customer_fields
    @helper.customer :first_name => 'Cody', :last_name => 'Fauser', :email => 'cody@example.com'
    assert_field 'buyerName', 'Cody'
    assert_field 'buyerEmail', 'cody@example.com'
  end

  def test_address_mapping
    @helper.billing_address :address1 => '1 My Street',
                            :address2 => '',
                            :city => 'Leeds',
                            :state => 'Yorkshire',
                            :zip => 'LS2 7EE',
                            :country  => 'CA'

    assert_field 'buyerAddress1', '1 My Street'
    assert_field 'buyerCity', 'Leeds'
    assert_field 'buyerState', 'Yorkshire'
    assert_field 'buyerZip', 'LS2 7EE'
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

  def test_calls_the_v1_api_url_when_the_token_is_v1
    stub_request(:post, BitPay::API_V1_URL).with(
      body: {
        orderID: '1234',
        price: '500',
        currency: 'USD',
        posData: { orderId: 1234 }.to_json,
        fullNotifications: "true",
        transactionSpeed: 'high',
        token: @token_v1,
      }.to_json,
      basic_auth: [@token_v1, ''],
      headers: {'x-bitpay-plugin-info' => 'BitPay_AM' + @helper.application_id + '_Client_v1.0.1909'},
    ).to_return(
      status: 200,
      body: { id: @invoice_id }.to_json
    )

    assert_equal @invoice_id, @helper.form_fields['id']
  end

  def test_calls_the_v2_api_url_when_the_token_is_v2
    stub_request(:post, BitPay::API_V2_URL).with(
      body: {
        orderID: '1234',
        price: '500',
        currency: 'USD',
        posData: { orderId: 1234 }.to_json,
        fullNotifications: "true",
        transactionSpeed: 'high',
        token: @token_v2,
      }.to_json,
      headers: {'x-bitpay-plugin-info' => 'BitPay_AM' + @helper.application_id + '_Client_v2.0.1909'},
    ).to_return(
      status: 200,
      body: { data: { id: @invoice_id } }.to_json
    )

    helper = BitPay::Helper.new(1234, @token_v2, :amount => 500, :currency => 'USD')

    assert_equal @invoice_id, helper.form_fields['id']
  end
end
