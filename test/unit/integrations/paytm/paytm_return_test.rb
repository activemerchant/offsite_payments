require 'test_helper'

class PaytmReturnTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @paytm = Paytm::Return.new(http_raw_data_success, :credential1 => 'WorldP64425807474247', :credential2 => 'kbzk1DSbJiV_O3p5', :credential3 => 'Retail', :credential4 => 'worldpressplg')
  end

  def setup_failed_return
    @paytm = Paytm::Return.new(http_raw_data_failure, :credential1 => 'WorldP64425807474247', :credential2 => 'kbzk1DSbJiV_O3p5', :credential3 => 'Retail', :credential4 => 'worldpressplg')
  end

  def test_success
    assert @paytm.success?
    assert_equal 'Completed', @paytm.status('100PT012','10')
  end

  def test_failure_is_successful
    setup_failed_return
    assert_equal 'Failed', @paytm.status('100PT012', '10')
  end

  def test_treat_initial_failures_as_pending
    setup_failed_return
    assert_equal 'Failed', @paytm.notification.status
  end

  def test_return_has_notification
    notification = @paytm.notification

    assert notification.complete?
    assert_equal 'Completed', notification.status
    assert notification.invoice_ok?('100PT012')
    assert notification.amount_ok?(BigDecimal.new('10.00'),BigDecimal.new('0.00'))
    assert_equal "TXN_SUCCESS", notification.transaction_status
    assert_equal '494157', @paytm.notification.transaction_id
    assert_equal 'DC', @paytm.notification.type
    assert_equal 'INR', notification.currency
    assert_equal '100PT012', notification.invoice
    assert_equal 'WorldP64425807474247', notification.account
    assert_equal '10.00', notification.gross
    #assert_equal '0.00', notification.discount
    #assert_equal nil, notification.offer_description
    #assert_equal 'Product Info', notification.product_info
    #assert_equal 'test@example.com', notification.customer_email
    #assert_equal '9999999999', notification.customer_phone
    #assert_equal 'paytm-Admin', notification.customer_first_name
    #assert_equal '', notification.customer_last_name
    #assert_equal ["", "", "", "", "", "", "", "", "", ""], notification.user_defined
    assert_equal checksum, notification.checksum
    assert_equal 'Txn Successful', notification.message
    assert notification.checksum_ok?
  end

  private

  def http_raw_data_success
	"MID=WorldP64425807474247&ORDERID=100PT012&TXNAMOUNT=10&CURRENCY=INR&TXNID=494157&BANKTXNID=201512236592678&STATUS=TXN_SUCCESS&RESPCODE=01&RESPMSG=Txn+Successful&TXNDATE=2015-12-23+16:06:22.0&GATEWAYNAME=ICICI&BANKNAME=ICICI&PAYMENTMODE=DC&CHECKSUMHASH=UgTNNLvjnFi/vxElGKstkBHJGbNCWDi+9pTnz5PhgpYefo89+HfI3fGdmkwhRCjLVKw/CIebMnER62PxVj2p2RDkZCOKXvr3JxOr75/AoLY="
    #"mihpayid=403993715508030204&mode=CC&status=success&unmappedstatus=captured&key=merchant_id&txnid=4ba4afe87f7e73468f2a&amount=10.00&discount=0.00&addedon=2013-05-10 18 32 30&productinfo=Product Info&firstname=paytm-Admin&lastname=&address1=&address2=&city=&state=&country=&zipcode=&email=test@example.com&phone=1234567890&udf1=&udf2=&udf3=&udf4=&udf5=&udf6=&udf7=&udf8=&udf9=&udf10=&hash=#{checksum}&field1=313069903923&field2=999999&field3=59117331831301&field4=-1&field5=&field6=&field7=&field8=&PG_TYPE=HDFC&bank_ref_num=59117331831301&bankcode=CC&error=E000&cardnum=512345XXXXXX2346&cardhash=766f0227cc4b4c5f773a04cb31d8d1c5be071dd8d08fe365ecf5e2e5c947546d"
  end

  def http_raw_data_failure
	"MID=WorldP64425807474247&ORDERID=100PT012&TXNAMOUNT=10&CURRENCY=INR&TXNID=494157&BANKTXNID=201512236592678&STATUS=TXN_FAILURE&RESPCODE=330&RESPMSG=Invalid+Checksum&TXNDATE=2015-12-23+16:06:22.0&GATEWAYNAME=ICICI&BANKNAME=ICICI&PAYMENTMODE=DC&CHECKSUMHASH=YuvvHSOZvWs3xlKYQ0uzkwvfwU1zH1MtTwUmkUgcAPhAoomgeZA139JxYCN2fxS46mSWsmbjWq/e8QJp0F+h2q8LXOlitokQNlfUFxLoqMM="
    
  end

  def checksum
  "UgTNNLvjnFi/vxElGKstkBHJGbNCWDi+9pTnz5PhgpYefo89+HfI3fGdmkwhRCjLVKw/CIebMnER62PxVj2p2RDkZCOKXvr3JxOr75/AoLY="
    #Digest::SHA512.hexdigest("secret|success|||||||||||test@example.com|paytm-Admin|Product Info|10.00|4ba4afe87f7e73468f2a|merchant_id")
  end

end
