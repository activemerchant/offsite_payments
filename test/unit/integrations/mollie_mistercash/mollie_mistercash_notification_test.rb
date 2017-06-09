require 'test_helper'

class MollieMistercashNotificationTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @required_options = { :credential1 => '1234567' }
    @notification = MollieMistercash::Notification.new("id=tr_h2PhlwFaX8", @required_options)

    MollieMistercash::API.stubs(:new).with('1234567').returns(@mock_api = mock())
  end

  def test_accessors
    assert @notification.complete?
    assert_equal "tr_h2PhlwFaX8", @notification.transaction_id
    assert_equal "1234567", @notification.api_key
  end

  def test_acknowledgement_sets_params
    @mock_api.expects(:get_request).returns(SUCCESSFUL_CHECK_PAYMENT_STATUS_RESPONSE)
    assert @notification.acknowledge

    assert_equal 'Completed', @notification.status
    assert_equal "EUR", @notification.currency
    assert_equal 12345, @notification.gross_cents
    assert_equal "123.45", @notification.gross
    assert_equal Money.from_amount(123.45, 'EUR'), @notification.amount

    assert_equal "123", @notification.item_id
  end

  def test_respond_to_acknowledge
    assert @notification.respond_to?(:acknowledge)
  end

  def test_raises_without_required_options
    assert_raises(ArgumentError) { MollieMistercash::Notification.new("", :credential1 => '123') }
    assert_raises(ArgumentError) { MollieMistercash::Notification.new('id=123', {}) }
  end

  SUCCESSFUL_CHECK_PAYMENT_STATUS_RESPONSE = JSON.parse(<<-JSON)
    {
      "id":"tr_h2PhlwFaX8",
      "mode":"test",
      "createdDatetime":"2014-03-03T10:17:05.0Z",
      "status":"paid",
      "amount":"123.45",
      "description":"My order description",
      "method":"mistercash",
      "metadata":{
        "order":"123"
      },
      "details":null,
      "links":{
        "paymentUrl":"https://www.mollie.com/paymentscreen/mistercash/testmode/ca8195a3dc8d5cbf2f7b130654abe5a5",
        "redirectUrl":"https://example.com/return"
      }
    }
  JSON

  PENDING_CHECK_PAYMENT_STATUS_RESPONSE = JSON.parse(<<-JSON)
    {
      "id":"tr_h2PhlwFaX8",
      "mode":"test",
      "createdDatetime":"2014-03-03T10:17:05.0Z",
      "status":"open",
      "amount":"123.45",
      "description":"My order description",
      "method":"mistercash",
      "metadata":{
        "order":"123"
      },
      "details":null,
      "links":{
        "paymentUrl":"https://www.mollie.com/paymentscreen/mistercash/testmode/ca8195a3dc8d5cbf2f7b130654abe5a5",
        "redirectUrl":"https://example.com/return"
      }
    }
  JSON
end
