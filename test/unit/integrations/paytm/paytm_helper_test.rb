require 'test_helper'


class PaytmHelperTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    # user on order page wants to pay, sends request to our controller 
    # with order_id, amont etc, where
    # @params will be set. then Helper will transform them to actual params
    # sent to Paytm
    @order   = 'order-500'
    @account = 'FreshD33860006728322'
    @params  = {
      merchant_key:      'lalala789789789798',
      amount:            500,
      transaction_type: 'DEFAULT',
      device_used:      'WEB',
      customer: {
        email: 'hi@hi.com',
        phone: '7777777777',
        id:    1
      },
      industry_type_id: 'Retail',
      website:          'FreshDispatchweb',
      notify_url:       'http://hiiiii.ru' 
    }
    # @merchant_key = @params[:merchant_key]
    

    @helper = Paytm::Helper.new @order.clone, @account.clone, @params.clone
    # @helper must be defined here, so in test we can use    
    #   assert_field('currency', 'USD') 
    #   (same as::: assert_equal 'USD', @helper.fields['currency'] :::method)
    #   
    # method
  end


  # assert_field(field, value)
  # assert_equal value, @helper.fields[field]
  def test_basic_helper_fields
    assert_field 'ORDER_ID',     @order
    assert_field 'MID',          @account
    assert_field 'TXN_AMOUNT',   @params[:amount].to_s

    assert_field 'CALLBACK_URL', @params[:notify_url].to_s
  end


  def test_mentioned_in_params_but_nonasigned_fields
    assert_field 'REQUEST_TYPE', @params[:transaction_type].to_s
  end

  # Paytm::Helper.mappings == @helper.mappings
  def test_completely_custom_fields
    assert_field 'CHANNEL_ID',  @params[:device_used].to_s

    # customer mapping
    assert_field 'EMAIL',     @params[:customer][:email].to_s
    assert_field 'MOBILE_NO', @params[:customer][:phone].to_s
    assert_field 'CUST_ID',   @params[:customer][:id].to_s

    # provided by paytm
    assert_field 'INDUSTRY_TYPE_ID', @params[:industry_type_id].to_s
    assert_field 'WEBSITE',          @params[:website].to_s
  end

  def test_generated_checksum
    generated_checksum = @helper.fields['CHECKSUMHASH']
    assert_instance_of String, generated_checksum

    assert_true Paytm::Checksum.verify @helper.fields.except('CHECKSUMHASH'), generated_checksum, @params.delete(:merchant_key)
  end

end
