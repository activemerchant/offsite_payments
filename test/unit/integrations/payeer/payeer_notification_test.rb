require 'test_helper'

class PayeerNotificationTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @payeer = Payeer::Notification.new(http_raw_data, :secret => 'secret')
    @notification_with_wrong_signature = Payeer::Notification.new(http_raw_data_with_wrong_signature, :secret => 'secret')
  end

  def test_accessors
    assert @payeer.complete?
    assert_equal "success", @payeer.status
    assert_equal "123456", @payeer.m_operation_id
    assert_equal "Yandex", @payeer.m_operation_ps
    assert_equal "500", @payeer.item_id
    assert_equal "50.00", @payeer.gross
  end

  def test_acknowledgement
    assert @payeer.acknowledge
  end

  def test_respond_to_acknowledge
    assert @payeer.respond_to?(:acknowledge)
  end

  def test_wrong_signature
    assert !@notification_with_wrong_signature.acknowledge
  end

  private
  def http_raw_data
    "m_operation_id=123456&m_operation_ps=Yandex&m_operation_date=21.12.2012 21:12&m_operation_pay_date=21.12.2012 21:12&m_shop=5005&m_orderid=500&m_amount=50.00&m_curr=RUB&m_desc=MQ==&m_status=success&m_sign=3F5809868CD41364D6CB7C7DEC7D2A86C5F93713829DBD39A63001348CFC21FD"
  end

  def http_raw_data_with_wrong_signature
    "m_operation_id=123456&m_operation_ps=Yandex&m_operation_date=21.12.2012 21:12&m_operation_pay_date=21.12.2012 21:12&m_shop=5005&m_orderid=500&m_amount=50.00&m_curr=RUB&m_desc=MQ==&m_status=success&m_sign=wrong"
  end
end
