require 'test_helper'

class EpayKazakhstanHelperTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    EpayKazakhstan.configure do |config|
      config.merchant_certificate_id = '00C182B189'
      config.merchant_name = 'Test shop'
      config.private_key_pass = 'nissan'
      config.merchant_id = '92061101'
      config.cert_file_path = File.expand_path('../kkbca.cer', __FILE__)
      config.private_key_path = File.expand_path('../test_prv.pem', __FILE__)
    end

    @helper = EpayKazakhstan::Helper.new({id: 10, amount: 10, currency: 'KZT'}, nil, back_link: 'localhost/back', post_link: 'localhost/post', email: 'khai.le@live.com')
  end

  def test_basic_helper_fields
    assert_field 'email', 'khai.le@live.com'
    assert_field 'BackLink', 'localhost/back'
    assert_field 'PostLink', 'localhost/post'
    assert_field 'Signed_Order_B64', "PGRvY3VtZW50PjxtZXJjaGFudCBjZXJ0X2lkPSIwMEMxODJCMTg5IiBuYW1lPSJUZXN0IHNob3AiPjxvcmRlciBvcmRlcl9pZD0iMDAwMDEwIiBhbW91bnQ9IjEwIiBjdXJyZW5jeT0iMzk4Ij48ZGVwYXJ0bWVudCBtZXJjaGFudF9pZD0iOTIwNjExMDEiIGFtb3VudD0iMTAiLz48L29yZGVyPjwvbWVyY2hhbnQ+PG1lcmNoYW50X3NpZ24gdHlwZT0iUlNBIj5kNlVsZU43Mjd0Yi9WNEQxVGp4UlIyQlRmMno0ZkdaREVPNlgzeUFXOFZhaVVFU3U2WDE2aGsrWSs5dHhld3lYbmFRQ3JGb202WXFiajlsbGhMcWpXUT09PC9tZXJjaGFudF9zaWduPjwvZG9jdW1lbnQ+"
  end
end