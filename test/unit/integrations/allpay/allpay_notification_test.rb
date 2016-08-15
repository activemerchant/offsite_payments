class AllpayNotificationTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    OffsitePayments::Integrations::Allpay.hash_key = '5294y06JbISpM5x9'
    OffsitePayments::Integrations::Allpay.hash_iv = 'v77hoKGq4kWxNNIS'
    @allpay = Allpay::Notification.new(http_raw_data)
  end

  def test_params
    p = @allpay.params

    assert_equal 12, p.size
    assert_equal 'Credit_CreditCard', p['PaymentType']
    assert_equal 'BC586977559ED305BEC4C334DFDC881D', p['CheckMacValue']
    assert_equal '2014/04/15 15:39:38', p['PaymentDate']
  end

  def test_complete?
    assert @allpay.complete?
  end

  def test_checksum_ok?
    assert @allpay.checksum_ok?

    # Should preserve mac value
    assert @allpay.params['CheckMacValue'].present?
  end

  private

  def http_raw_data
    # Sample notification from test environment
    "TradeAmt=2760&RtnMsg=付款成功&MerchantTradeNo=81397545579&PaymentType=Credit_CreditCard&TradeNo=1404151506342901&SimulatePaid=1&MerchantID=2000132&TradeDate=2014-04-15 15:06:34&PaymentDate=2014/04/15 15:39:38&PaymentTypeChargeFee=0&CheckMacValue=BC586977559ED305BEC4C334DFDC881D&RtnCode=1"
  end
end
