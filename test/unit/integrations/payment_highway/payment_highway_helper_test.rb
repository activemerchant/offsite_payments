require 'test_helper'

class PaymentHighwayHelperTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    SecureRandom.expects(:uuid).returns("super-uuid")

    @helper = PaymentHighway::Helper.new('order-500','test_merchantId', {
      amount: 500,
      currency: 'EUR',
      credential2: "test", #sph-account,
      credential3: "testKey", #sph-account-key
      credential4: "testSecret" #sph-account-secret
    })
    @helper.description "Description"
    @helper.language "fi"
    @helper.success_url "https://example.com/success"
    @helper.failure_url "https://example.com/failure"
    @helper.cancel_url "https://example.com/cancel"
  end

  def test_basic_helper_fields
    assert_field "sph-amount", '500'
    assert_field "sph-order", 'order-500'
    assert_field "sph-account", 'test'
    assert_field "sph-merchant", 'test_merchantId'
    assert_field "sph-request-id", 'super-uuid'
    assert_field "sph-currency", 'EUR'
    assert_field "sph-timestamp", @helper.fields["sph-timestamp"]
    assert_field "language", 'fi'
    assert_field "description", 'Description'
  end

  def test_signature
    puts @helper.generate_signature

    assert_equal generate_signature(@helper.fields["sph-timestamp"], 'test', 'test_merchantId', 'testKey', 'testSecret'), @helper.generate_signature
  end

  private def generate_signature timestamp, account, merchant, account_key, account_secret
    contents = ["POST"]
    contents << "/form/view/pay_with_card"
    contents << "sph-account:#{account}"
    contents << "sph-amount:500"
    contents << "sph-cancel-url:https://example.com/cancel"
    contents << "sph-currency:EUR"
    contents << "sph-failure-url:https://example.com/failure"
    contents << "sph-merchant:#{merchant}"
    contents << "sph-order:order-500"
    contents << "sph-request-id:super-uuid"
    contents << "sph-success-url:https://example.com/success"
    contents << "sph-timestamp:#{timestamp}"
    contents << ""
    "SPH1 #{account_key} #{OpenSSL::HMAC.hexdigest('sha256', account_secret, contents.join("\n"))}"
  end
end
