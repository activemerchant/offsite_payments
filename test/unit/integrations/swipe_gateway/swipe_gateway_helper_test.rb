require 'test_helper'

class SwipeGatewayHelperTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @public_key = fixtures(:swipe_gateway)[:public_key]
    @private_key = fixtures(:swipe_gateway)[:private_key]

    @helper = SwipeGateway::Helper.new('order-test21', @public_key, :amount => 500, :currency => 'EUR', :credential2 => @private_key)
  end

  def test_helper_hash
    SwipeGateway::SwipeApi::SSLPoster.any_instance.expects(:ssl_post).returns(http_raw_data)

    assert_equal '82584dba0341e195bbd95b6f0df59186fc078fd4fa1b2744243d2aa2ec39dcef', @helper.form_fields['hash']
  end

  def test_raise_error_on_invalid_json
    SwipeGateway::SwipeApi::SSLPoster.any_instance.expects(:ssl_post).returns('qwerty')

    assert_raise ActionViewHelperError do
      @helper.form_fields
    end
  end

  def test_raise_error_on_error_response
    SwipeGateway::SwipeApi::SSLPoster.any_instance.expects(:ssl_post).returns('{"errors":"an error"}')
    
    assert_raise ActionViewHelperError do
      @helper.form_fields
    end
  end

  def http_raw_data
    http_raw_data = '{
      "id": 10,
      "full_page_checkout": "https://swipegateway.com/lv/client/payment/82584dba0341e195bbd95b6f0df59186fc078fd4fa1b2744243d2aa2ec39dcef/full_page/",
      "iframe_checkout": "https://swipegateway.com/lv/client/payment/82584dba0341e195bbd95b6f0df59186fc078fd4fa1b2744243d2aa2ec39dcef/iframe/",
      "errors": [],
      "timestamp": 1482931995
    }'    
  end
end
