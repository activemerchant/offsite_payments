require 'test_helper'

class MaldivesPaymentGatewayNotificationTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @maldives_payment_gateway = MaldivesPaymentGateway::Notification.new(http_raw_data)
  end

  def test_accessors
    assert @maldives_payment_gateway.complete?
    assert_equal "", @maldives_payment_gateway.status
    assert_equal "", @maldives_payment_gateway.transaction_id
    assert_equal "", @maldives_payment_gateway.item_id
    assert_equal "", @maldives_payment_gateway.gross
    assert_equal "", @maldives_payment_gateway.currency
    assert_equal "", @maldives_payment_gateway.received_at
    assert @maldives_payment_gateway.test?
  end

  def test_compositions
    assert_equal Money.new(3166, 'USD'), @maldives_payment_gateway.amount
  end

  # Replace with real successful acknowledgement code
  def test_acknowledgement

  end

  def test_send_acknowledgement
  end

  def test_respond_to_acknowledge
    assert @maldives_payment_gateway.respond_to?(:acknowledge)
  end

  private
  def http_raw_data
    ""
  end
end
