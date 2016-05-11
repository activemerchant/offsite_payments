require 'test_helper'

class PaymentHighwayHelperTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    SecureRandom.expects(:uuid).returns("super-uuid")

    @helper = PaymentHighway::Helper.new('order-500','test_merchantId', {
      amount: 500,
      currency: 'EUR',
    })
    @helper.description "Description"
    @helper.language "fi"
    @helper.sph_account = "test"
    @helper.account_key = "testKey"
    @helper.account_secret = "testSecret"
  end

  def test_basic_helper_fields
    assert_field "sph-amount", '500'
    assert_field "sph-order", 'order-500'
    assert_field "sph-account", 'test'
    assert_field "sph-merchant", 'test_merchantId'
    assert_field "sph-account-key", 'testKey'
    assert_field "sph-account-secret", 'testSecret'
    assert_field "sph-request-id", 'super-uuid'
    assert_field "sph-currency", 'EUR'
    assert_field "sph-timestamp", @helper.fields["sph-timestamp"]
    assert_field "language", 'fi'
    assert_field "description", 'Description'
  end

  def test_signature
    assert_equal generate_signature(@helper.fields["sph-timestamp"], 'test', 'test_merchantId', 'testSecret'), @helper.generate_signature
  end

  #def test_customer_fields
    #@helper.customer :first_name => 'Cody', :last_name => 'Fauser', :email => 'cody@example.com'
    #assert_field '', 'Cody'
    #assert_field '', 'Fauser'
    #assert_field '', 'cody@example.com'
  #end

  #def test_address_mapping
    #@helper.billing_address :address1 => '1 My Street',
                            #:address2 => '',
                            #:city => 'Leeds',
                            #:state => 'Yorkshire',
                            #:zip => 'LS2 7EE',
                            #:country  => 'CA'

    #assert_field '', '1 My Street'
    #assert_field '', 'Leeds'
    #assert_field '', 'Yorkshire'
    #assert_field '', 'LS2 7EE'
  #end

  #def test_unknown_address_mapping
    #@helper.billing_address :farm => 'CA'
    #assert_equal 3, @helper.fields.size
  #end

  #def test_unknown_mapping
    #assert_nothing_raised do
      #@helper.company_address :address => '500 Dwemthy Fox Road'
    #end
  #end

  #def test_setting_invalid_address_field
    #fields = @helper.fields.dup
    #@helper.billing_address :street => 'My Street'
    #assert_equal fields, @helper.fields
  #end
  private def generate_signature timestamp, account, merchant, account_secret
    contents = ["POST"]
    contents << "/form/view/pay_with_card"
    contents << "sph-account=#{account}"
    contents << "sph-merchant=#{merchant}"
    contents << "sph-order=order-500"
    contents << "sph-request-id=super-uuid"
    contents << "sph-amount=500"
    contents << "sph-currency=EUR"
    contents << "sph-timestamp=#{timestamp}"
    contents << "sph-success-url=https://v1-hub-staging.sph-test-solinor.com/success"
    contents << "sph-failure-url=https://v1-hub-staging.sph-test-solinor.com/failure"
    contents << "sph-cancel-url=https://v1-hub-staging.sph-test-solinor.com/cancel"
    contents << "language=fi"
    contents << "description=Description"
    OpenSSL::HMAC.hexdigest('sha256', account_secret, contents.join("\n"))
  end
end
