require 'test_helper'

class RazorpayNotificationTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @key_secret = fixtures(:razorpay)[:key_secret]
    @razorpay = Razorpay::Notification.new(http_raw_data, :credential2=>@key_secret)
  end

  def test_accessors
    assert_equal "Completed", @razorpay.status
    assert_equal "pay_2Yfh8NYF0L66CD", @razorpay.transaction_id
    assert_equal "INR", @razorpay.currency
  end

  def test_compositions
    assert_equal Money.new(5000, 'INR'), @razorpay.amount
  end

  def test_gross
    assert_equal 50.00, @razorpay.gross
  end

  # Replace with real successful acknowledgement code
  def test_acknowledgement
    assert @razorpay.acknowledge
  end

  def test_invalid_acknowledgement
    razorpay = Razorpay::Notification.new(http_invalid_data, :credential2=>@key_secret)
    assert_false razorpay.acknowledge
  end

  def test_respond_to_acknowledge
    assert @razorpay.respond_to?(:acknowledge)
  end

  def test_status
    assert_equal 'Completed', @razorpay.status
  end

  private
  def http_raw_data
    "razorpay_payment_id=pay_2Yfh8NYF0L66CD&\
amount=5000&\
currency=INR&\
merchant_order_id=order_id&\
signature=bcefe8e65bb11e0f23b68a5e00084612b186b71c\
&http_status_code=200"
  end

  def http_invalid_data
    "razorpay_payment_id=pay_2Yfh8NYF0L66CD&\
amount=5000&\
currency=INR&\
merchant_order_id=order_id&\
signature=bcefe8e65bb11e0f23b68a5e00084612b186b71d"
  end
end
