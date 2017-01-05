require 'test_helper'

class SwipeGatewayNotificationTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @swipe_gateway = SwipeGateway::Notification.new(http_raw_data, {:credential1 => 'public_key', :credential2 => 'private_key'})
  end

  def test_accessors
    assert @swipe_gateway.complete?
    assert_equal "Complete", @swipe_gateway.status
    assert_equal "326", @swipe_gateway.transaction_id
    assert_equal "TEST30", @swipe_gateway.item_id
    assert_equal "2.75", @swipe_gateway.gross
    assert_equal "test@swipegateway.com", @swipe_gateway.payer_email
    assert_equal 1483465701, @swipe_gateway.received_at
    assert @swipe_gateway.test?
  end

  def test_compositions
    assert_equal Money.new(275, 'EUR'), @swipe_gateway.amount
  end

  def test_respond_to_acknowledge
    assert @swipe_gateway.respond_to?(:acknowledge)
  end

  def test_acknowledgement
    SwipeGateway::SwipeApi::SSLPoster.any_instance.expects(:ssl_get).returns(http_raw_data)
    assert @swipe_gateway.acknowledge
  end

  def test_failed_acknowledgement
    SwipeGateway::SwipeApi::SSLPoster.any_instance.expects(:ssl_get).returns(failed_http_raw_data)
    refute @swipe_gateway.acknowledge
  end

  def test_invalid_json_in_acknowledgement
    SwipeGateway::SwipeApi::SSLPoster.any_instance.expects(:ssl_get).returns("{qqqqq}")
    refute @swipe_gateway.acknowledge
  end

  private

  def http_raw_data
    '{"id": 326, "iframe_send_invoice": false, "comment": "", "skip_capture": false, "custom_invoice_link": "", "creation_channel": 20, "payment_id": 67, "products": [{"description": "Green tea XL pack", "price": 0.3, "quantity": 1.0}], "subtotal": 0.36, "discount_percent": 0, "discount_amount": 0.0, "vat_enabled": true, "vat_rate": 0.21, "vat_amount": 0.06, "total": 2.75, "action": "send_email", "link": "http://127.0.0.1:8000/lv/i/019ic83a1eec", "request_info": [], "date": "2017-01-03T17:48:21.203347+00:00", "notes": "", "client_fee": 0.0, "client_base_fee_amount": 0.0, "max_merchant_fee_amount": 1.0, "min_merchant_fee_amount": 0.0, "currency": {"id": 1, "code": "EUR", "sign": "\u20ac", "iso_code": 978, "postfix": true}, "fee": 0.21, "fee_details": {"base_fee_amount": 0.2, "fee_rate": 3.0}, "client": {"email": "test@swipegateway.com", "phone": "", "first_name": "", "last_name": "", "personal_code": "", "company_name": "", "legal_name": "", "registration_nr": "", "vat_payer_nr": "", "address": "", "iban": "", "swift": ""}, "timeout_seconds": 0, "due_date": "2017-02-03", "fee_type": "merchant", "number": "TEST30", "language": "lv", "success_redirect": "", "failure_redirect": "", "status": "paid", "cancel_redirect": "", "referrer": "", "invoice_id": 67, "hash": "c83aa39c1ea91fb81350efcbd86fa3e0cfeb1cf150e4845d4d5e9c908d171eec", "amount": 2.75, "deposit": 0.0, "is_test": true, "paid_on": "2017-01-03T17:48:21.203347+00:00"}'
  end

  def failed_http_raw_data
    '{"id": 326, "iframe_send_invoice": false, "comment": "", "skip_capture": false, "custom_invoice_link": "", "creation_channel": 20, "payment_id": 67, "products": [{"description": "Green tea XL pack", "price": 0.3, "quantity": 1.0}], "subtotal": 0.36, "discount_percent": 0, "discount_amount": 0.0, "vat_enabled": true, "vat_rate": 0.21, "vat_amount": 0.06, "total": 2.75, "action": "send_email", "link": "http://127.0.0.1:8000/lv/i/019ic83a1eec", "request_info": [], "date": "2017-01-03T17:48:21.203347+00:00", "notes": "", "client_fee": 0.0, "client_base_fee_amount": 0.0, "max_merchant_fee_amount": 1.0, "min_merchant_fee_amount": 0.0, "currency": {"id": 1, "code": "EUR", "sign": "\u20ac", "iso_code": 978, "postfix": true}, "fee": 0.21, "fee_details": {"base_fee_amount": 0.2, "fee_rate": 3.0}, "client": {"email": "test@swipegateway.com", "phone": "", "first_name": "", "last_name": "", "personal_code": "", "company_name": "", "legal_name": "", "registration_nr": "", "vat_payer_nr": "", "address": "", "iban": "", "swift": ""}, "timeout_seconds": 0, "due_date": "2017-02-03", "fee_type": "merchant", "number": "TEST30", "language": "lv", "success_redirect": "", "failure_redirect": "", "status": "created", "cancel_redirect": "", "referrer": "", "invoice_id": 67, "hash": "c83aa39c1ea91fb81350efcbd86fa3e0cfeb1cf150e4845d4d5e9c908d171eec", "amount": 2.75, "deposit": 0.0, "is_test": true, "paid_on": "2017-01-03T17:48:21.203347+00:00"}'
  end

end
