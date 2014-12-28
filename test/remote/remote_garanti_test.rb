require 'test_helper'
require 'remote_test_helper'

# NOTE: tests may fail randomly because Garanti returns random(!) responses for their test server
class RemoteGarantiTest < Test::Unit::TestCase

  def setup
     @garanti = Garanti::Notification.new('')

    @gateway = GarantiGateway.new(fixtures(:garanti))

    @options = {
      :order_id => generate_unique_id,
      :billing_address => address,
      :description => 'Store Purchase'
    }
  end

  def teardown
    $KCODE = @original_kcode if @original_kcode
  end

  def test_raw
    assert_equal "https://sanalposprov.garanti.com.tr/servlet/gt3dengine", service_url
    assert_nothing_raised do
      assert_equal false, @garanti.acknowledge
    end
  end
 
  def test_invalid_login
    gateway = GarantiGateway.new(
                :provision_user_id => 'PROVOOS',
                :user_id => 'PROVOOS',
                :terminal_id => '10000174',
                :merchant_id => '',
                :password => ''
              )
    assert response = gateway.purchase(@amount, @options)
    assert_failure response
    assert_equal '0651', response.params["reason_code"]
  end
end
