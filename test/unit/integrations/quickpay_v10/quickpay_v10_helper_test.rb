require 'test_helper'

class QuickpayV10HelperTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @helper = QuickpayV10::Helper.new('order-500','24352435', amount: 500, currency: 'USD', credential2: "paymentwindowapikey")
    @helper.return_url 'http://example.com/ok'
    @helper.cancel_return_url 'http://example.com/cancel'
    @helper.notify_url 'http://example.com/notify'
  end

  def test_basic_helper_fields
    assert_field 'merchant_id', '24352435'
    assert_field 'amount', '500'
    assert_field 'order_id', 'order500'
  end
  
  def test_form_fields
    assert_equal '4d726eae3c73aa032afabb4217d052d6bf3431bea548c20c1e9b0bbdcba267d1', @helper.form_fields['checksum']
  end

  def test_generate_checksum
    assert_equal '4d726eae3c73aa032afabb4217d052d6bf3431bea548c20c1e9b0bbdcba267d1', @helper.generate_checksum
  end

  def test_unknown_mapping
    assert_nothing_raised do
      @helper.company_address address: '500 Dwemthy Fox Road'
    end
  end

  def test_setting_invalid_address_field
    fields = @helper.fields.dup
    @helper.billing_address :street => 'My Street'
    assert_equal fields, @helper.fields
  end
end
