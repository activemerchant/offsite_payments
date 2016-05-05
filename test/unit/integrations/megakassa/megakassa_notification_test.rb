require 'test_helper'

class MegakassaNotificationTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @megakassa = Megakassa::Notification.new(http_raw_data, :secret => 'secret')
  end

  def test_accessors
    assert @megakassa.complete?

    assert_equal '1',              @megakassa.uid
    assert_equal '500',            @megakassa.gross
    assert_equal '500',            @megakassa.gross_shop
    assert_equal '525',            @megakassa.gross_client
    assert_equal 'RUB',            @megakassa.currency
    assert_equal '123',            @megakassa.order_id
    assert_equal '1',              @megakassa.payment_method_id
    assert_equal 'Payment Method', @megakassa.payment_method_title
    assert_equal 'test@email.net', @megakassa.client_email
  end

  def test_compositions
    assert_equal Money.new(50000, 'RUB'), @megakassa.amount
    assert_equal Money.new(50000, 'RUB'), @megakassa.amount_shop
    assert_equal Money.new(52500, 'RUB'), @megakassa.amount_client
  end

  # Replace with real successful acknowledgement code
  def test_acknowledgement
    assert @megakassa.acknowledge
  end

  def test_respond_to_acknowledge
    assert @megakassa.respond_to?(:acknowledge)
  end

  def test_wrong_signature
    @megakassa = Megakassa::Notification.new(http_raw_data_with_wrong_signature, :secret => 'secret')
    assert !@megakassa.acknowledge
  end

  private
  def http_raw_data
    'uid=1&amount=500&amount_shop=500&amount_client=525&currency=RUB&order_id=123&payment_method_id=1&payment_method_title=Payment Method&client_email=test@email.net&signature=3fd0bbda0fdc820838d0726e94fccc00'
  end

  def http_raw_data_with_wrong_signature
    'uid=1&amount=500&amount_shop=500&amount_client=525&currency=RUB&order_id=123&payment_method_id=1&payment_method_title=Payment Method&client_email=test@email.net&signature=wrong'
  end
end
