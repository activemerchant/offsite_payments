require 'test_helper'

class BitPayModuleTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_notification_method
    assert_instance_of BitPay::Notification, BitPay.notification('{"name":"cody"}', {})
  end

  def test_return_method
    assert_instance_of BitPay::Return, BitPay.return('{"name":"cody"}', {})
  end

  def test_invoicing_url_returns_v1_url_when_token_is_less_than_44
    api_token = 'a' * 43

    assert_equal BitPay::API_V1_URL, BitPay.invoicing_url(api_token)
  end

  def test_invoicing_url_returns_v1_url_when_token_is_equal_to_44_and_contains_special_chars
    api_token = ('a' * 43)

    %w(0 O I l).each do |char|
      assert_equal BitPay::API_V1_URL, BitPay.invoicing_url(api_token + char)
    end
  end

  def test_invoicing_url_returns_v1_url_when_token_is_bigger_than_44_and_contains_special_chars
    api_token = ('a' * 46)

    %w(0 O I l).each do |char|
      assert_equal BitPay::API_V1_URL, BitPay.invoicing_url(api_token + char)
    end
  end

  def test_invoicing_url_returns_v1_url_when_token_is_equal_to_44_and_does_not_contain_special_chars
    assert_equal BitPay::API_V2_URL, BitPay.invoicing_url('a' * 44)
  end

  def test_invoicing_url_returns_v1_url_when_token_is_bigger_than_44_and_does_not_contain_special_chars
    assert_equal BitPay::API_V2_URL, BitPay.invoicing_url('a' * 45)
  end
end
