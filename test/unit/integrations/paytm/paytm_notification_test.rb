require 'test_helper'

class PaytmNotificationTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @secret = 'kbzk1DSbJiV_O3p5'
    @notification = Paytm::Notification.new(http_raw_data, :credential2 => @secret)
  end

  def test_accessors
    assert_equal 'order-500', @notification.item_id
    assert_equal 'USD', @notification.currency
    assert_equal '123.45', @notification.gross
    assert_equal 'blorb123', @notification.transaction_id
    assert_equal 'Completed', @notification.status
    assert_equal 'helloworld', @notification.message
    assert @notification.test?
  end

  def test_compositions
    assert_equal Money.from_amount(123.45, 'USD'), @notification.amount
  end

  def test_acknowledge_valid_signature
    assert @notification.acknowledge
  end

  def test_acknowledge_valid_signature_with_extra_parameter
    @notification = Paytm::Notification.new(http_raw_data_extra_parameter, :credential2 => @secret)

    assert @notification.acknowledge
  end

  def test_acknowledge_valid_uppercase_signature
    @notification = Paytm::Notification.new(http_raw_data_uppercase_signature, :credential2 => @secret)

    assert @notification.acknowledge
  end

  def test_acknowledge_invalid_signature
    @notification = Paytm::Notification.new(http_raw_data_invalid_signature, :credential2 => @secret)

    assert !@notification.acknowledge
  end

  private

  def http_raw_data
    'x_account_id=zork&x_reference=order-500&x_currency=USD&x_test=true&x_amount=123.45&x_gateway_reference=blorb123&x_timestamp=2014-03-24T12:15:41Z&x_result=completed&x_signature=DtfuqciPcF0p8/TgUyArPmPlH3DvCDmGPadyX37Rqfs=&x_message=helloworld'
  end

  def http_raw_data_extra_parameter
    'utm_nooverride=1&x_account_id=zork&x_reference=order-500&x_currency=USD&x_test=true&x_amount=123.45&x_gateway_reference=blorb123&x_timestamp=2014-03-24T12:15:41Z&x_result=completed&x_signature=eX7sljlxRCm2p64J26o3VQitsbHfUdzYYNSnBgbMMl8='
  end

  def http_raw_data_uppercase_signature
    'x_account_id=zork&x_reference=order-500&x_currency=USD&x_test=true&x_amount=123.45&x_gateway_reference=blorb123&x_timestamp=2014-03-24T12:15:41Z&x_result=completed&x_signature=eX7sljlxRCm2p64J26o3VQitsbHfUdzYYNSnBgbMMl8='
  end

  def http_raw_data_invalid_signature
    'x_account_id=zork&x_reference=order-500&x_currency=USD&x_test=true&x_amount=123.45&x_gateway_reference=blorb123&x_timestamp=2014-03-24T12:15:41Z&x_result=completed&x_signature=ex7sljlxRom2p64J26o3VQitsbHfUdzYYNSnBgbmml8='
  end
end
