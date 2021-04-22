require 'test_helper'
require 'remote_test_helper'

class RemoteSwipeGatewayTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    public_key = fixtures(:swipe_gateway)[:public_key]
    private_key = fixtures(:swipe_gateway)[:private_key]
    @helper = SwipeGateway::Helper.new(123, public_key, :credential2 => private_key, :currency => 'EUR', :amount => 0.40)
    @notification = SwipeGateway::Notification.new(
      notify_callback_http_raw_data, 
      {:credential1 => public_key, :credential2 => private_key}
    )

    @notification_invalid = SwipeGateway::Notification.new(
      notify_callback_http_raw_data, 
      {:credential1 => public_key, :credential2 => 'invalid_key'}
    )    
  end

  def test_payment_hash_properly_generated
    @helper.customer :email => "invesari@gmail.com"
    assert @helper.form_fields["hash"]
  end

  def test_payment_verified
    assert @notification.acknowledge
  end

  def test_invalid_credentials
    refute @notification_invalid.acknowledge
  end    

  def notify_callback_http_raw_data
    '{"id": 56620, "iframe_send_invoice": false, "comment": "", "skip_capture": false, "custom_invoice_link": "", "creation_channel": 20, "payment_id": 56620, "products": [{"description": "Green tea XL pack", "price": 28.5, "quantity": 5.0}, {"description": "Black tea M pack", "price": 12.35, "quantity": 2.0}], "subtotal": 202.31, "discount_percent": 0, "discount_amount": 0.0, "vat_enabled": true, "vat_rate": 0.21, "vat_amount": 35.11, "total": 202.31, "action": "send_email", "link": "https://swipegateway.com/lv/i/0gQci7b4cea8c", "request_info": [], "date": null, "notes": "", "client_fee": 0.0, "client_base_fee_amount": 0.0, "max_merchant_fee_amount": 0.0, "min_merchant_fee_amount": 0.0, "currency": {"id": 1, "code": "EUR", "sign": "\u20ac", "iso_code": 978, "postfix": true}, "fee": 6.27, "fee_details": {"base_fee_amount": 0.2, "fee_rate": 3.0}, "client": {"email": "test@example.com", "phone": "", "first_name": "", "last_name": "", "personal_code": "", "company_name": "", "legal_name": "", "registration_nr": "", "vat_payer_nr": "", "address": "", "iban": "", "swift": ""}, "timeout_seconds": 0, "due_date": "2017-02-04", "fee_type": "merchant", "number": "TEST317", "language": "lv", "success_redirect": "", "failure_redirect": "", "status": "paid", "cancel_redirect": "", "referrer": "", "invoice_id": 56620, "hash": "7b4ce87ab6d7b4131d1fcd1f9b96f74e608549eedba484f7f9f6b356f187ea8c", "amount": 202.31, "deposit": 0.0, "is_test": true, "paid_on": "2017-01-04T09:32:50.067579+00:00", "errors": [], "timestamp": 1483535388}'
  end

end