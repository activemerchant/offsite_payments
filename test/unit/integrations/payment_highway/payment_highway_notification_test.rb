require 'test_helper'

class PaymentHighwayNotificationTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @payment_highway = PaymentHighway::Notification.new(http_raw_data)
  end

  def test_accessors
    assert @payment_highway.complete?
    assert_equal "", @payment_highway.status
    assert_equal "", @payment_highway.transaction_id
    assert_equal "", @payment_highway.item_id
    assert_equal "", @payment_highway.gross
    assert_equal "", @payment_highway.currency
    assert_equal "", @payment_highway.received_at
    assert @payment_highway.test?
  end

  def test_compositions
    assert_equal Money.new(3166, 'USD'), @payment_highway.amount
  end

  # Replace with real successful acknowledgement code
  def test_acknowledgement

  end

  def test_send_acknowledgement
  end

  def test_respond_to_acknowledge
    assert @payment_highway.respond_to?(:acknowledge)
  end

  private
  def http_raw_data
    ""
  end
end
