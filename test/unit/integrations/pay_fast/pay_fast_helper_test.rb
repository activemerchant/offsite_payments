require 'test_helper'

class PayFastHelperTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup_without_passphrase
    @helper = PayFast::Helper.new(123, '10000100', :amount => 500, :credential2 => '46f0cd694581a')
  end

  def setup_with_passphrase
    @helper = PayFast::Helper.new(123, '10000100', :amount => 500, :credential2 => '46f0cd694581a', :credential3 => 'passphrase')
  end

  def assing_required_fields
    @helper.item_name = 'ZOMG'
    @helper.notify_url = 'http://test.com/pay_fast/paid'
  end

  def test_basic_helper_fields
    setup_without_passphrase
    assing_required_fields

    assert_field 'merchant_id', '10000100'
    assert_field 'merchant_key', '46f0cd694581a'
    assert_field 'notify_url', 'http://test.com/pay_fast/paid'
    assert_field 'amount', '500'
    assert_field 'm_payment_id', '123'
    assert_field 'item_name', 'ZOMG'
  end

  def test_request_signature_string_without_passphrase
    setup_without_passphrase
    assing_required_fields

    assert_equal 'merchant_id=10000100&merchant_key=46f0cd694581a&notify_url=http%3A%2F%2Ftest.com%2Fpay_fast%2Fpaid&m_payment_id=123&amount=500&item_name=ZOMG', @helper.request_signature_string
  end

  def test_request_signature_string_with_passphrase
    setup_with_passphrase
    assing_required_fields

    assert_equal 'merchant_id=10000100&merchant_key=46f0cd694581a&notify_url=http%3A%2F%2Ftest.com%2Fpay_fast%2Fpaid&m_payment_id=123&amount=500&item_name=ZOMG&passphrase=passphrase', @helper.request_signature_string('passphrase')
  end

  def test_request_generated_signature_without_passphrase
    setup_without_passphrase

    assert_equal '45aa67464a46c9cf837257365866b247', @helper.generate_signature(:request)
  end

  def test_request_generated_signature_with_passphrase
    setup_with_passphrase

    assert_equal '226ceb67c56f21c25004fb62a8afa16a', @helper.generate_signature(:request, passphrase: 'passphrase')
  end
end
