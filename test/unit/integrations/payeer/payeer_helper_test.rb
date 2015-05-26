require 'test_helper'

class PayeerHelperTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @helper = Payeer::Helper.new('500','5005', :amount => 50, :currency => 'RUB', :description => '1', :secret => 'secret')
  end

  def test_basic_helper_fields
    assert_field 'm_orderid', '500'
    assert_field 'm_shop', '5005'
    assert_field 'm_amount', '50.00'
    assert_field 'm_curr', 'RUB'
    assert_field 'm_desc', 'MQ=='
  end

  def test_signature_string
    assert_equal '5005:500:50.00:RUB:MQ==:secret', @helper.generate_signature_string
  end

  def test_signature_string_with_empty_amount
    helper = Payeer::Helper.new('500','5005', :description => '1', :secret => 'secret')
    assert_equal '5005:500:0.00:USD:MQ==:secret', helper.generate_signature_string
  end
end
