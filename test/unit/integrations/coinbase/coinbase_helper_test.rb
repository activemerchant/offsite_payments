require 'test_helper'

class CoinbaseHelperTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @helper = Coinbase::Helper.new('order-500', 'api_key', :amount => 500, :currency => 'USD', :credential2 => 'api_secret')
  end

  def test_helper_id
    Net::HTTP.any_instance.expects(:request).returns(stub(:body => '{"success":true,"button":{"code":"test123"}}'))

    assert_equal 'test123', @helper.form_fields['id']
  end

  def test_raise_error_on_invalid_json
    Net::HTTP.any_instance.expects(:request).returns(stub(:body => 'totally not json'))

    assert_raise ActionViewHelperError do
      @helper.form_fields
    end
  end

  def test_raise_error_on_error_response
    Net::HTTP.any_instance.expects(:request).returns(stub(:body => '{"error":"something bad happened"}'))

    assert_raise ActionViewHelperError do
      @helper.form_fields
    end
  end
end
