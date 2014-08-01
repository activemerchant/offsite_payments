require 'test_helper'

class MercadoPagoNotificationTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @mercado_pago = MercadoPago::Notification.new(custom_ipn_raw_data("approved"))
  end

  def test_accessors
    assert @mercado_pago.complete?
    assert_equal "Completed", @mercado_pago.status
    assert_equal 1234567, @mercado_pago.transaction_id
    assert_equal "RTV-25640", @mercado_pago.item_id
    assert_equal 100, @mercado_pago.gross
    assert_equal "ARS", @mercado_pago.currency
    assert_equal "2014-01-30T18:14:24Z", @mercado_pago.received_at
    assert_equal "payer@example.com", @mercado_pago.payer_email
    assert_equal "collector@example.com", @mercado_pago.receiver_email
    assert_equal @mercado_pago.test, true
  end

  def test_pending
    @mercado_pago = MercadoPago::Notification.new(custom_ipn_raw_data("pending"))
    refute @mercado_pago.complete?
    assert_equal "Pending", @mercado_pago.status
  end

  def test_rejected
    @mercado_pago = MercadoPago::Notification.new(custom_ipn_raw_data("rejected"))
    refute @mercado_pago.complete?
    assert_equal "Failed", @mercado_pago.status
  end

  def test_compositions
    assert_equal Money.new(10000, 'ARS'), @mercado_pago.amount
  end

  def test_respond_to_acknowledge
    assert @mercado_pago.respond_to?(:acknowledge)
  end

  private

  def custom_ipn_raw_data(status, status_detail = "some_status_detail")
    <<-DATA
        {
          "id": 1234567,
          "created_from": "963",
          "reason": "test",
          "shipping_cost": 0,
          "net_received_amount": 100,
          "activation_uri": null,
          "date_created": "2014-01-30T18:14:24Z",
          "order_id": "RTV-25640",
          "card_id": "12345678",
          "version": 1,
          "timestamp": 1352139265093,
          "released": "no",
          "total_paid_amount": 100,
          "collector": {
              "id": 1111111,
              "first_name": null,
              "phone": {
                  "extension": null,
                  "area_code": "54",
                  "number": "111111111"
              },
              "email": "collector@example.com",
              "nickname": "TESTCOLLECTOR",
              "identification": {
                  "number": null,
                  "type": "CPF"
              },
              "last_name": "TEST"
          },
          "last_modified": "2012-11-05T18:14:24Z",
          "first_six_digits": 444444,
          "last_modified_by": 6490823,
          "external_reference": "RTV-25640",
          "transaction_amount": 100,
          "card": {
              "id": "1111111",
              "number_id": "ASD123213ASDAS12312SDAS124312"
          },
          "statement_descriptor": null,
          "client_id": "CHO-Lite",
          "marketplace": "NONE",
          "ow_payment_id": 123456789,
          "modified_from": "CHO-Lite",
          "status_code": "0",
          "currency_id": "ARS",
          "authorization_date": "2012-11-05T18:14:24Z",
          "sponsor_id": null,
          "status": "#{status.to_s}",
          "site_id": "MLB",
          "status_detail": "#{status_detail.to_s}",
          "operation_type": "regular_payment",
          "mercadopago_fee": 3.63,
          "buyer_fee": 0,
          "last_four_digits": 5054,
          "transaction_id": "12345678_676d3123667777977",
          "installments": 3,
          "extra_part": null,
          "money_release_date": null,
          "finance_charge": 0,
          "sandbox": true,
          "payer": {
              "id": 123456789,
              "first_name": "Test",
              "phone": {
                  "extension": null,
                  "area_code": "011",
                  "number": "1234567890"
              },
              "email": "payer@example.com",
              "nickname": "TEST",
              "identification": {
                  "number": null,
                  "type": null
              },
              "last_name": "TEST"
          },
          "item_id": "456789",
          "last_modified_from": "963",
          "date_approved": "2012-11-05T18:14:24Z",
          "authorization_code": "987654",
          "payment_method": {
              "id": "master",
              "payment_type": "credit_card"
          }
        }
    DATA
  end
end
