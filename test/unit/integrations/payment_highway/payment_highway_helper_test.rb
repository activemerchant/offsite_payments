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
    assert_equal generate_signature(@helper.fields["sph-timestamp"], 'test', 'test_merchantId', 'testKey', 'testSecret'), @helper.generate_signature
  end

  def test_success_signature
    params = { "sph-amount" => 4000,
               "signature" => "SPH1 testKey b9b31e9ed9d355d0b01371556c064bd0f13b0c9d0c1bc2e9c4f2ee9bdacaaff5",
               "sph-account" => "test",
               "sph-currency" => "EUR",
               "sph-merchant" => "test_merchantId",
               "sph-transaction-id" =>"c4cf8c3d-0c86-409c-b3f5-b7bb2c422d1c",
               "sph-order" => "104200",
               "sph-timestamp" => "2016-05-16T07:06:46Z",
               "sph-request-id" => "694ab577-a1a3-4426-a378-13df65266b1b",
               "sph-success" => "OK"
    }

    assert_true PaymentHighway::Helper.valid_signature?("testKey", "testSecret", params)
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
