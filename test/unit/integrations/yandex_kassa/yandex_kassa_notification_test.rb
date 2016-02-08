require 'test_helper'

class YandexKassaNotificationTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @yandex_kassa = YandexKassa::Notification.new(http_raw_data)
  end

  def test_accessors
    assert @yandex_kassa.complete?
    assert_equal "", @yandex_kassa.status
    assert_equal "", @yandex_kassa.transaction_id
    assert_equal "", @yandex_kassa.item_id
    assert_equal "", @yandex_kassa.gross
    assert_equal "", @yandex_kassa.currency
    assert_equal "", @yandex_kassa.received_at
    assert @yandex_kassa.test?
  end

  def test_compositions
    assert_equal Money.new(3166, 'USD'), @yandex_kassa.amount
  end

  # Replace with real successful acknowledgement code
  def test_acknowledgement

  end

  def test_send_acknowledgement
  end

  def test_respond_to_acknowledge
    assert @yandex_kassa.respond_to?(:acknowledge)
  end

  private
  def http_raw_data
    ""
  end
end
