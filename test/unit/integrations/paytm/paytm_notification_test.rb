require 'test_helper'

class PaytmNotificationTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @checksum = "2TbZn8eQ5JP37cbnJGehTLMlkYhqZLxEUh3drQPn8SX3W44Ou3noDpY7CN0wBe1PIxopTzBvQRAsCtmIPzZtikp0dPj7DleHRG3olIiAvKA="
    @paytm = Paytm::Notification.new(http_raw_data, credential1: 'WorldP64425807474247', credential2: 'kbzk1DSbJiV_O3p5', credential3: 'Retail', credential4: 'worldpressplg')
  end

  def test_accessors
    assert @paytm.complete?
    assert_equal 'Completed', @paytm.status
    assert_equal '494157', @paytm.transaction_id
    assert_equal 'TXN_SUCCESS', @paytm.transaction_status
    assert_equal '10.00', @paytm.gross
    assert_equal 'INR', @paytm.currency
    assert_equal true, @paytm.invoice_ok?('100PT012')
    assert_equal true, @paytm.amount_ok?(BigDecimal.new('10.00'))
    assert_equal 'CC', @paytm.type
    assert_equal '100PT012', @paytm.invoice
    assert_equal 'WorldP64425807474247', @paytm.account
    assert_equal @checksum, @paytm.checksum
    assert_equal true, @paytm.checksum_ok?
  end

  def test_compositions
    assert_equal '10.00', @paytm.gross
  end

  def test_acknowledgement
    assert @paytm.acknowledge
  end

  def test_checksum_ok_returns_false_when_checksum_is_nil
    @paytm = Paytm::Notification.new(
      http_raw_data.gsub("&CHECKSUMHASH=#{@checksum}", ''),
      credential1: 'WorldP64425807474247',
      credential2: 'kbzk1DSbJiV_O3p5',
      credential3: 'Retail',
      credential4: 'worldpressplg'
    )

    assert_equal false, @paytm.checksum_ok?
  end

  private

  def http_raw_data
    "MID=WorldP64425807474247&ORDERID=100PT012&TXNAMOUNT=10&CURRENCY=INR&TXNID=494157&BANKTXNID=201512236592678&STATUS=TXN_SUCCESS&RESPCODE=01&RESPMSG=Txn Successful&TXNDATE=2015-12-23 16:06:22.0&GATEWAYNAME=ICICI&BANKNAME=ICICI&PAYMENTMODE=CC&MERC_UNQ_REF=100PT012&TXNDATETIME=2018-12-04 22:08:45.0&CHECKSUMHASH=#{@checksum}"
  end
end
