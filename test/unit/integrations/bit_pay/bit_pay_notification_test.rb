require 'test_helper'

class BitPayNotificationTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @token_v1 = 'g82hEYhfRkhIlX5HJEqO8w5giRVeyGwsJ1wDPRvx8'
    @token_v2 = '5v2K2rwuWQbnKexiQF9Eu6xdCVg7HFtkFNXarGEq9vLR'
    @invoice_id = '98kui1gJ7FocK41gUaBZxG'
    @bit_pay = BitPay::Notification.new(http_raw_data, credential1: @token_v1)
  end

  def test_accessors
    assert @bit_pay.complete?
    assert_equal "Completed", @bit_pay.status
    assert_equal "98kui1gJ7FocK41gUaBZxG", @bit_pay.transaction_id
    assert_equal 10.00, @bit_pay.gross
    assert_equal "USD", @bit_pay.currency
    assert_equal 1370539476654, @bit_pay.received_at
    assert_equal 123, @bit_pay.item_id
  end

  def test_compositions
    assert_equal Money.from_amount(10.00, 'USD'), @bit_pay.amount
  end

  def test_successful_acknowledgement_with_v1_api_token
    stub_request(:get, "#{BitPay.invoicing_url(@token_v1)}/#{@invoice_id}").
      to_return(status: 200, body: http_raw_data)

    assert @bit_pay.acknowledge
  end

  def test_successful_acknowledgement_with_v2_api_token
    stub_request(:get, "#{BitPay.invoicing_url(@token_v2)}/#{@invoice_id}").
      to_return(status: 200, body: http_raw_data)

    notification = BitPay::Notification.new(http_raw_data, credential1: @token_v2)

    assert notification.acknowledge
  end

  def test_acknowledgement_error
    stub_request(:get, "#{BitPay.invoicing_url(@token_v1)}/#{@invoice_id}").
      to_return(status: 200, body: { error: 'Doesnt match'}.to_json)

    assert !@bit_pay.acknowledge
  end

  private
  def http_raw_data
    {
      "id"=> @invoice_id,
      "orderID"=>"123",
      "url"=>"https://bitpay.com/invoice/98kui1gJ7FocK41gUaBZxG",
      "status"=>"complete",
      "btcPrice"=>"0.0295",
      "price"=>"10.00",
      "currency"=>"USD",
      "invoiceTime"=>"1370539476654",
      "expirationTime"=>"1370540376654",
      "currentTime"=>"1370539573956",
      "posData" => '{"orderId":123}'
    }.to_json
  end
end
