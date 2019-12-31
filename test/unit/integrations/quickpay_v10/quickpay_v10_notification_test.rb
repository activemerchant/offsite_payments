require 'test_helper'

class QuickpayV10NotificationTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @quickpay = QuickpayV10::Notification.new(http_raw_data, credential3: "test", 
      checksum_header: "96d68908b5f49efc92985517751059e0f4b512e338418525c5f6594331432cfa")
  end

  def test_accessors
    assert @quickpay.complete?
    assert_equal "20000", @quickpay.status
    assert_equal 7, @quickpay.transaction_id
    assert_equal "Order7", @quickpay.item_id
    assert_equal "1.23", @quickpay.gross
    assert_equal "DKK", @quickpay.currency
    assert_equal Time.iso8601("2015-03-05T10:06:18Z"), @quickpay.received_at
  end

  def test_compositions
    assert_equal Money.from_amount(1.23, 'DKK'), @quickpay.amount
  end

  def test_acknowledgement
    assert @quickpay.acknowledge
  end

  def test_failed_acknnowledgement
    @quickpay = QuickpayV10::Notification.new(http_raw_data, credential3: "test", checksum_header: "badchecksumbad")
    assert !@quickpay.acknowledge
  end

  def test_quickpay_attributes
    assert_equal true, @quickpay.accepted
    assert_equal "nets", @quickpay.acquirer
  end

  def test_generate_checksum
    assert_equal "96d68908b5f49efc92985517751059e0f4b512e338418525c5f6594331432cfa", @quickpay.generate_checksum
  end

  def test_respond_to_acknowledge
    assert @quickpay.respond_to?(:acknowledge)
  end

  private
  def http_raw_data
    <<-END_POST
    {
      "id": 7,
      "order_id": "Order7",
      "accepted": true,
      "test_mode": true,
      "branding_id": null,
      "variables": {},
      "acquirer": "nets",
      "operations": [
        {
          "id": 1,
          "type": "authorize",
          "amount": 123,
          "pending": false,
          "qp_status_code": "20000",
          "qp_status_msg": "Approved",
          "aq_status_code": "000",
          "aq_status_msg": "Approved",
          "data": {},
          "created_at": "2015-03-05T10:06:18+00:00"
        }
      ],
      "metadata": {
        "type": "card",
        "brand": "quickpay-test-card",
        "last4": "0008",
        "exp_month": 8,
        "exp_year": 2019,
        "country": "DNK",
        "is_3d_secure": false,
        "customer_ip": "195.41.47.54",
        "customer_country": "DK"
      },
      "created_at": "2015-03-05T10:06:18Z",
      "balance": 0,
      "currency": "DKK"
    }
END_POST
  end
end
