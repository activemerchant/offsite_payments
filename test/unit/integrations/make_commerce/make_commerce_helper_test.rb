require 'test_helper'

class MakeCommerceHelperTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @options = fixtures(:make_commerce) 
    @helper  = MakeCommerce::Helper.new('order-500','cody@example.com', 
    	:amount => 5.67, 
    	:currency => 'EUR', 
    	:notify_url => 'https://example.com/notify',
    	:return_url => 'https://example.com/return',
    	:credential2 => @options[:shop_id],
    )
  end

  def test_basic_helper_fields
    assert_field 'amount', '5.67'
    assert_field 'reference', 'order-500'
    assert_field 'shop', 'f7741ab2-7445-45f9-9af4-0d0408ef1e4c'
    assert_field 'notification_url', 'https://example.com/notify'
    assert_field 'return_url', 'https://example.com/return'
  end
  
end
