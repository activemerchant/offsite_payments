require 'test_helper'
require 'pry'
class YandexKassaNotificationTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @yandex_kassa = YandexKassa::Notification.new(http_raw_data)
  end

  def test_accessors
    assert @yandex_kassa.complete?
    assert_equal 86.23, @yandex_kassa.gross
    assert_equal :rub, @yandex_kassa.currency
    assert_equal "2011-05-04T20:38:00.000 04:00", @yandex_kassa.received_at
  end

  def test_compositions
    assert_equal Money.new(8623, 'RUB'), @yandex_kassa.amount
  end

  # Replace with real successful acknowledgement code
  def test_acknowledgement
    assert @yandex_kassa.acknowledge('coolpasswd')
  end

  def test_respond_to_acknowledge
    assert @yandex_kassa.respond_to?(:acknowledge)
  end

  private
  def http_raw_data
    "requestDatetime=2011-05-04T20:38:00.000+04:00&md5=38b46a3adae71186d470522f1995e174&invoiceId=1234567&shopId=13&shopArticleId=456&customerNumber=8123294469&orderCreatedDatetime=2011-05-04T20:38:00.000+04:00&paymentPayerCode=42007148320&orderSumAmount=87.10&orderSumCurrencyPaycash=643&orderSumBankPaycash=1001&shopSumAmount=86.23&shopSumCurrencyPaycash=643&shopSumBankPaycash=1001&paymentType=AC"
  end
end
