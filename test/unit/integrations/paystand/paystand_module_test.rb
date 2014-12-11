require 'test_helper'

class PaystandTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_notification_method
    assert_instance_of Paystand::Notification, Paystand.notification('{"org_id":"52","txn_id":"1735","recurring_id":"","consumer_id":"563","pre_fee_total":50,"fee_merchant_owes":0,"rate_merchant_owes":0,"fee_consumer_owes":0.3,"rate_consumer_owes":1.35,"total_amount":51.65,"amount":51.65,"tax":"0.00","shipping_handling":"0.00","payment_status":"paid","completion_status":"completed","success":"1","rail":"card","currency":"US","order_id":"order-500","order_token":""}')
  end

  def test_test_mode
    OffsitePayments.mode = :test
    assert_equal 'https://sandbox.paystand.co/fcommerce/cart_checkout', Paystand.service_url
  end

  def test_test_mode
    OffsitePayments.mode = :dev
    assert_equal 'https://dev.paystand.localhost/fcommerce/cart_checkout', Paystand.service_url
  end

  def test_production_mode
    OffsitePayments.mode = :production
    assert_equal 'https://app.paystand.com/fcommerce/cart_checkout', Paystand.service_url
  ensure
    OffsitePayments.mode = :test
  end

  def test_invalid_mode
    OffsitePayments.mode = :zoomin
    assert_raise(StandardError){ Paypal.service_url }
  ensure
    OffsitePayments.mode = :test
  end

end
