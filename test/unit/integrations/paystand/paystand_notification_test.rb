require 'test_helper'

# sandbox api key
PS_API_KEY = 'axr2RqZNFAJA9jelggHnmTXWzgPfBa6omk1OrsM0FIJfXRkvyS6oXDusTg9i70RRYJXxc+nmDNPttL2GfbAKV9A'

class PaystandNotificationTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    OffsitePayments::mode = :test
    @paystand = Paystand::Notification.new(http_raw_data)
  end

  def test_accessors
    assert @paystand.complete?
    assert_equal "paid", @paystand.status
    assert_equal "3628", @paystand.transaction_id
    assert_equal "order-500", @paystand.item_id
    assert_equal 2.77, @paystand.gross
    assert_equal "US", @paystand.currency
    assert @paystand.test?
  end

  def test_compositions
    assert_equal Money.new(277, 'USD'), @paystand.amount
  end

  # Replace with real successful acknowledgement code
  def test_acknowledgement
    assert @paystand.acknowledge(PS_API_KEY)
  end

  def test_respond_to_acknowledge
    assert @paystand.respond_to?(:acknowledge)
  end

  private
  def http_raw_data
   # %*{"org_id":"52","txn_id":"1735","recurring_id":"","consumer_id":"563","pre_fee_total":50,"fee_merchant_owes":0,"rate_merchant_owes":0,"fee_consumer_owes":0.3,"rate_consumer_owes":1.35,"total_amount":51.65,"amount":51.65,"tax":"0.00","shipping_handling":"0.00","payment_status":"paid","completion_status":"completed","success":"1","rail":"card","currency":"US","order_id":"order-500","order_token":""}*
   %*{"org_id":"4175","txn_id":"3628","recurring_id":"649","consumer_id":"3490","pre_fee_total":2.21,"fee_merchant_owes":0,"rate_merchant_owes":0,"fee_consumer_owes":0.5,"rate_consumer_owes":0.06,"total_amount":2.77,"amount":2.77,"tax":"0.00","shipping_handling":"1.09","payment_status":"paid","completion_status":"incomplete","success":"1","rail":"card","currency":"US","order_id":"order-500","order_token":"order-token-500","meta":"{'order_id':'order-500','order_token':'order-token-500}"}*
  end
end
