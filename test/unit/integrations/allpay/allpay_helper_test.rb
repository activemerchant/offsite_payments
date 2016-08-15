require 'test_helper'

class AllpayHelperTest < Test::Unit::TestCase
  include OffsitePayments::Integrations
  
  def setup
  end

  def test_check_mac_value
    @helper = Allpay::Helper.new 'sdfasdfa', '12345678'
    @helper.add_field 'ItemName', 'sdfasdfa'
    @helper.add_field 'MerchantID', '12345678'
    @helper.add_field 'MerchantTradeDate', '2013/03/12 15:30:23'
    @helper.add_field 'MerchantTradeNo','allpay_1234'
    @helper.add_field 'PaymentType', 'allpay'
    @helper.add_field 'ReturnURL', 'http:sdfasdfa'
    @helper.add_field 'TotalAmount', '500'
    @helper.add_field 'TradeDesc', 'dafsdfaff'

    OffsitePayments::Integrations::Allpay.hash_key = 'xdfaefasdfasdfa32d'
    OffsitePayments::Integrations::Allpay.hash_iv = 'sdfxfafaeafwexfe'

    @helper.encrypted_data

    assert_equal '40D9A6C00A4A78A300ED458237071BDA', @helper.fields['CheckMacValue']
  end

  def test_check_mac_value_with_special_characters
    @helper = Allpay::Helper.new 'R435729525344', '2000132'
    @helper.add_field 'ItemName', 'Guava'
    @helper.add_field 'MerchantID', '2000132'
    @helper.add_field 'MerchantTradeDate', '2014/08/07 17:17:33'
    @helper.add_field 'MerchantTradeNo','R435729525344'
    @helper.add_field 'PaymentType', 'aio'
    @helper.add_field 'ReturnURL', 'http://example.com/notify'
    @helper.add_field 'TotalAmount', '1000'
    @helper.add_field 'TradeDesc', ( '~`@#$%*^()_-+={}[]|\\"\'>,.?/:;' + "\t" )
    @helper.add_field 'ChoosePayment', 'Credit'

    OffsitePayments::Integrations::Allpay.hash_key = '5294y06JbISpM5x9'
    OffsitePayments::Integrations::Allpay.hash_iv = 'v77hoKGq4kWxNNIS'

    @helper.encrypted_data

    assert_equal 'DF1186B7B8651F44380BEF8AB8A5727B', @helper.fields['CheckMacValue']
  end

  def test_url_encoding
    encoded = Allpay::url_encode('-_.!~*() @#$%^&=+;?/\\><`[]{}:\'",|')
    assert_equal encoded, '-_.!%7e*()+%40%23%24%25%5e%26%3d%2b%3b%3f%2f%5c%3e%3c%60%5b%5d%7b%7d%3a%27%22%2c%7c'
  end
end
