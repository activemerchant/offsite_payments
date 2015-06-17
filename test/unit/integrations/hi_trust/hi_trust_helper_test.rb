require 'test_helper'

class HiTrustHelperTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @helper = HiTrust::Helper.new('order-500','cody@example.com', :amount => 500, :currency => 'USD')
  end

  def test_basic_helper_fields
    assert_field 'storeid', 'cody@example.com'
    assert_field 'amount', '500'
    assert_field 'ordernumber', 'order-500'
    assert_field 'currency', 'USD'
    assert_field 'depositflag', '0'
  end

  def test_depositflag_option
    @helper = HiTrust::Helper.new('order-500','cody@example.com', {:amount => 500, :currency => 'USD', :deposit_flag => '1'})
    assert_field 'depositflag', '1'
  end
end
