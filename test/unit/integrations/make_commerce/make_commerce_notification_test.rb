require 'test_helper'

class MakeCommerceNotificationTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @make_commerce = MakeCommerce::Notification.new(http_raw_data)
  end

  def test_accessors
    assert @make_commerce.complete?
    assert_equal "completed", @make_commerce.status
    assert_equal "123abc", @make_commerce.item_id
    assert_equal "12.95", @make_commerce.gross
    assert_equal "EUR", @make_commerce.currency
    assert_equal "80c0e701-bd4e-452d-b32f-9aa2e082ae95", @make_commerce.transaction_id
  end

  def test_compositions
    assert_equal Money.new(1295, 'EUR'), @make_commerce.amount
  end

  def test_acknowledgement
    assert @make_commerce.acknowledge("pfOsGD9oPaFEILwqFLHEHkPf7vZz4j3t36nAcufP1abqT9l99koyuC1IWAOcBeqt")
  end

  def test_failed_acknowledgement
    assert_equal false, @make_commerce.acknowledge("pfOsGD9oPaFEILwqFLHEHkPf7vZz4j3t36nAcufP1abqT9l99koyuC1IWAOcBeqe")
  end

  def test_respond_to_acknowledge
    assert @make_commerce.respond_to?(:acknowledge)
  end

  private
  def http_raw_data
    {"type": "return", "json": '{"amount":"12.95","currency":"EUR","reference":"123abc","shop":"f7741ab2-7445-45f9-9af4-0d0408ef1e4c","transaction":"80c0e701-bd4e-452d-b32f-9aa2e082ae95","status":"COMPLETED","signature":"AF671A569E6EE40D5FDA8F702B28B3ABE4FCE7C6E8B43625C00BF47C03AE82559963C889B4C64AE4432686F27E4CEA5A453ACACBE22C81043E262A9B5FA855B8","message_time":"2016-09-23T08:43:57+0000","message_type":"payment_return","customer_name":"Tõõger Leõpäöld","merchant_data":null}', "mac": "789F1E379947CEA6639619E9B33260EF5FF724A9B0F657200417254EC8D6FC7D00E346A536377FA3FA8AE676C4B5CFCB0E6DFADD49F8D4F158E27BC71376D385"}
  end
end
