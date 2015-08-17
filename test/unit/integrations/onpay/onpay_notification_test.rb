require 'test_helper'

class OnpayNotificationTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @onpay_check = Onpay::Notification.new(http_check_raw_data, :secret => 'test')
    @onpay_pay = Onpay::Notification.new(http_pay_raw_data, :secret => 'test')
  end

  def test_check_accessors
    assert_equal "500.0", @onpay_check.gross
    assert_equal "55446",  @onpay_check.item_id
    assert_equal BigDecimal.new("500"), @onpay_check.amount
  end

  def test_check_acknowledgement
    assert @onpay_check.acknowledge
  end

  def test_check_response
    response = JSON.parse(@onpay_check.success_check_response)

    assert_equal 'f6f250cd7d29ac9947ed97ddaeebb7934849d21e', response['signature']
    assert_equal '55446', response['pay_for']
    assert_equal true, response['status']
  end

  def test_check_respond_to_acknowledge
    assert @onpay_check.respond_to?(:acknowledge)
  end

  def test_check_wrong_signature
    @onpay_check = Onpay::Notification.new(http_check_raw_data_with_wrong_signature, :secret => 'test')
    assert !@onpay_check.acknowledge
  end

  def test_pay_accessors
    assert_equal "500.0", @onpay_check.gross
    assert_equal "55446",  @onpay_pay.item_id
    assert_equal BigDecimal.new("3378.39"), @onpay_pay.amount
  end

  def test_pay_acknowledgement
    assert @onpay_pay.acknowledge
  end

  def test_pay_response
    response = JSON.parse(@onpay_pay.success_pay_response)

    assert_equal 'a25de68f9516e91ce8782b11abcd5801d7af20f4', response['signature']
    assert_equal '55446', response['pay_for']
    assert_equal true, response['status']
  end


  def test_pay_respond_to_acknowledge
    assert @onpay_pay.respond_to?(:acknowledge)
  end

  def test_pay_wrong_signature
    @onpay_pay = Onpay::Notification.new(http_pay_raw_data_with_wrong_signature, :secret => 'test')
    assert !@onpay_pay.acknowledge
  end

  private

  def http_check_raw_data
    '{
      "type":"check",
      "pay_for":"55446",
      "amount":500.0,
      "way":"RUR",
      "mode":"fix",
      "signature":"37eacbf65fa2982be8e2f82d1cb6aef23bf88aa0"
    }'
  end

  def http_check_raw_data_with_wrong_signature
    '{
      "type":"check",
      "pay_for":"55446",
      "amount":500.0,
      "way":"RUR",
      "mode":"fix",
      "signature":"WRONG"
    }'
  end

  def http_pay_raw_data
    "{\"type\":\"pay\",\"signature\":\"951e82110d1b796374ad3577f47e20a058c525dc\",\"pay_for\":\"55446\",\"user\":{\"email\":\"mail@mail.ru\",\"phone\":\"9631478946\",\"note\":\"\"},\"payment\":{\"id\":7121064,\"date_time\":\"2013-12-05T12:07:09+04:00\",\"amount\":102.0,\"way\":\"USD\",\"rate\":33.121445,\"release_at\":null},\"balance\":{\"amount\":3378.39,\"way\":\"RUR\"},\"order\":{\"from_amount\":102.0,\"from_way\":\"USD\",\"to_amount\":3378.39,\"to_way\":\"RUR\"},\"additional_params\":{\"onpay_ap_a1\":\"w\",\"onpay_ap_z1\":\"q\",\"onpay_ap_signature\":\"21ce6c2615c4b325ca406470b533e8ca76759dc4\"}}"
  end

  def http_pay_raw_data_with_wrong_signature
    "{\"type\":\"pay\",\"signature\":\"151e82110d1b796374ad3577f47e20a058c525dc\",\"pay_for\":\"55446\",\"user\":{\"email\":\"mail@mail.ru\",\"phone\":\"9631478946\",\"note\":\"\"},\"payment\":{\"id\":7121064,\"date_time\":\"2013-12-05T12:07:09+04:00\",\"amount\":102.0,\"way\":\"USD\",\"rate\":33.121445,\"release_at\":null},\"balance\":{\"amount\":3378.39,\"way\":\"RUR\"},\"order\":{\"from_amount\":102.0,\"from_way\":\"USD\",\"to_amount\":3378.39,\"to_way\":\"RUR\"},\"additional_params\":{\"onpay_ap_a1\":\"w\",\"onpay_ap_z1\":\"q\",\"onpay_ap_signature\":\"21ce6c2615c4b325ca406470b533e8ca76759dc4\"}}"
  end

end
