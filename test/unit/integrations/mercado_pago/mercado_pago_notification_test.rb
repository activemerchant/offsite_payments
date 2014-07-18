require 'test_helper'

class MercadoPagoNotificationTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup

    @mercado_pago = MercadoPago::Notification.new("collection_id=805289315", :credential1 => '1234567890', :credential2 => 'CLIENT_SECRET')

  end

  def test_accessors
    assert @mercado_pago.complete?
    assert_equal "Completed", @mercado_pago.status
    assert_equal 39865275, @mercado_pago.transaction_id
    assert_equal "RTV-25640", @mercado_pago.item_id
    assert_equal 814.81, @mercado_pago.gross
    assert_equal "ARS", @mercado_pago.currency
    assert_equal "2014-07-08T15:26:00.000-04:00", @mercado_pago.received_at
  end

  def test_respond_to_acknowledge
    assert @mercado_pago.respond_to?(:acknowledge)
  end

  private

  def oauth_raw_data
    <<-DATA
      {
        "access_token": "APP_USR-7007620073316002-071810-fb0f921bd4761b67bbc7182762658e92__F_M__-157723203",
        "token_type": "bearer",
        "expires_in": 21600,
        "scope": "offline_access read write",
        "refresh_token": "TG-53c9323ae4b0bd1014915431"
      }
    DATA
  end

  def http_raw_data
    <<-DATA
        {
            "id": 805289315,
            "site_id": "MLA",
            "date_created": "2014-07-08T15:26:00.000-04:00",
            "date_approved": "2014-07-08T15:26:00.000-04:00",
            "money_release_date": "2014-07-22T15:26:00.000-04:00",
            "last_modified": "2014-07-08T15:26:00.000-04:00",
            "sponsor_id": null,
            "collector_id": 157723203,
            "payer": {
                "id": 127729747,
                "email": "payermla01@hotmail.com",
                "phone": {
                    "number": "00000",
                    "area_code": null,
                    "extension": null
                }
            },
            "order_id": "RTV-25640",
            "external_reference": "RTV-25640",
            "merchant_order_id": 39865275,
            "reason": "test pref",
            "currency_id": "ARS",
            "transaction_amount": 814.81,
            "mercadopago_fee": 48.81,
            "net_received_amount": 766,
            "total_paid_amount": 814.81,
            "shipping_cost": 0,
            "coupon_amount": 0,
            "coupon_fee": 0,
            "finance_fee": 0,
            "discount_fee": 0,
            "coupon_id": null,
            "status": "approved",
            "status_detail": "accredited",
            "status_code": "0",
            "installments": 1,
            "account_money_amount": 0,
            "payment_type": "credit_card",
            "marketplace": "NONE",
            "operation_type": "regular_payment",
            "statement_descriptor": "WWW.MERCADOPAGO.COM",
            "cardholder": {
                "name": "ZãÃáÁàÀâÂäÄ¿¿éÉèÈêÊëËiIíÍìÌîÎïÏõÕóÓòÒôÔöÖuUúÚùÙûÛüÜçÇ’ñÑ",
                "identification": {
                    "number": "28987654",
                    "type": "DNI"
                }
            },
            "marketplace_fee": 0,
            "released": "no",
            "tags": [
                "new"
            ],
            "notification_url": null
        }
    DATA
  end
end
