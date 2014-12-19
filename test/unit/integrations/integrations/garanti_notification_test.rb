require 'test_helper'

class GarantiNotificationTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @garanti = Garanti::Notification.new(http_raw_data)
  end

  def test_accessors
    assert @garanti.complete?
    assert_equal "", @garanti.status
    assert_equal "", @garanti.transaction_id
    assert_equal "", @garanti.item_id
    assert_equal "", @garanti.gross
    assert_equal "", @garanti.currency
    assert_equal "", @garanti.received_at
    assert @garanti.test?
  end

  def test_compositions
    assert_equal Money.new(3166, 'USD'), @garanti.amount
  end

  # Replace with real successful acknowledgement code
  def test_acknowledgement

  end

  def test_send_acknowledgement
  end

  def test_respond_to_acknowledge
    assert @garanti.respond_to?(:acknowledge)
  end

  private
  def http_raw_data
    ""
  end
end
