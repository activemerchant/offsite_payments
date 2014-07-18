require 'test_helper'

class MPay24NotificationTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @m_pay24 = MPay24::Notification.new(http_raw_data)
  end

  def test_accessors
    assert @m_pay24.complete?
    assert_equal "BILLED", @m_pay24.status
    assert_equal "order-500", @m_pay24.transaction_id
    assert_equal "", @m_pay24.item_id
    assert_equal "", @m_pay24.gross
    assert_equal "", @m_pay24.currency
    assert_equal "", @m_pay24.received_at
  end

  def test_compositions
    assert_equal Money.new(3166, 'USD'), @m_pay24.amount
  end

  # Replace with real successful acknowledgement code
  def test_acknowledgement

  end

  def test_send_acknowledgement
  end

  def test_respond_to_acknowledge
    assert @m_pay24.respond_to?(:acknowledge)
  end

  private
  def http_raw_data
    ""
  end
end
