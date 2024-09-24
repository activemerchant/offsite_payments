require 'test_helper'

class HiTrustHelperTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @helper = HiTrust::Helper.new('order-500','cody@example.com', :amount => 500, :currency => 'USD')
  end

  def test_money_amount_to_cents
    @helper.amount = Money.from_amount(1.20, 'USD')
    assert_field 'amount', '120'
  end

  def test_basic_helper_fields
    assert_field 'storeid', 'cody@example.com'
    assert_field 'amount', '500'
    assert_field 'ordernumber', 'order-500'
    assert_field 'currency', 'USD'
  end
end
