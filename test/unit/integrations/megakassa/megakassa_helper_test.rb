require 'test_helper'

class MegakassaHelperTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @helper = Megakassa::Helper.new(123, 0, :amount => 500, :currency => 'RUB', :secret => 'secret', :description => 'test')
  end

  def test_basic_helper_fields
    assert_field 'shop_id',     '0'
    assert_field 'amount',      '500'
    assert_field 'currency',    'RUB'
    assert_field 'description', 'test'
    assert_field 'order_id',    '123'
  end

  def test_normalized_amount
    helper = Megakassa::Helper.new(123, 0, :amount => 100.00, :currency => 'RUB', :secret => 'secret', :description => 'test')
    assert_equal '100', helper.fields['amount']
  end

  def test_signature_string
    assert_equal '0:500:RUB:test:123:::1:secret', @helper.generate_signature_string
  end
end
