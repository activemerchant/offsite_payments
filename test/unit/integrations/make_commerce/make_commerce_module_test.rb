require 'test_helper'

class MakeCommerceTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_service_url_test
    OffsitePayments.mode = :test
    assert_equal 'https://payment-test.maksekeskus.ee/pay/1/link.html', MakeCommerce.service_url
  end

  def test_service_url_production
    OffsitePayments.mode = :production
    assert_equal 'https://payment.maksekeskus.ee/pay/1/link.html', MakeCommerce.service_url
  end

  
end
