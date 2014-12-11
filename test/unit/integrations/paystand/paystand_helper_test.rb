require 'test_helper'

# sandbox api key
PS_API_KEY = 'axr2RqZNFAJA9jelggHnmTXWzgPfBa6omk1OrsM0FIJfXRkvyS6oXDusTg9i70RRYJXxc+nmDNPttL2GfbAKV9A'

class PaystandHelperTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @helper = Paystand::Helper.new('order-500','4175', :amount => 221, :currency => 'US', :credential2 => PS_API_KEY)
  end

  def test_basic_helper_fields
    assert_field 'org_id', '4175'
    assert_field 'api_key', PS_API_KEY
    assert_field 'pre_fee_total', '221'
    assert_field 'currency', 'US'
    assert_field 'order_id', 'order-500'
  end

end
