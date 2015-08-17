require 'test_helper'

class OnHelperTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @helper = Onpay::Helper.new(
      123, 'like4u',
      :description => "Order description",
      :amount => 500,
      :pay_mode => "fix",
      :fail_url => "http://example.com/fail_url",
      :success_url => "http://example.com/success_url",
      :result_url => "http://example.com/result_url"
    )
  end

  def test_basic_helper_fields
    assert_field 'pay_mode', 'fix'
    assert_field 'price', '500.0'
    assert_field 'pay_for', '123'

    assert_equal "https://secure.onpay.ru/pay/like4u", @helper.credential_based_url
  end
end
