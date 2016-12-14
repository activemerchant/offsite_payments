require 'test_helper'

class RemotePaytmTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @paytm = Paytm::Notification.new(http_raw_data, credential1: 'WorldP64425807474247', credential2: 'kbzk1DSbJiV_O3p5', credential3: 'Retail', credential4: 'worldpressplg')
  end

  def test_raw
    OffsitePayments.mode = :production
    assert_equal 'https://secure.paytm.in/oltp-web/processTransaction', Paytm.service_url

    OffsitePayments.mode = :test
    assert_equal 'https://pguat.paytm.com/oltp-web/processTransaction', Paytm.service_url

    assert_nothing_raised do
      assert @paytm.checksum_ok?
    end
  end

  private

  def http_raw_data
    'MID=WorldP64425807474247&ORDERID=100PT012&TXNAMOUNT=10&CURRENCY=INR&TXNID=494157&BANKTXNID=201512236592678&STATUS=TXN_SUCCESS&RESPCODE=01&RESPMSG=Txn Successful&TXNDATE=2015-12-23 16:06:22.0&GATEWAYNAME=ICICI&BANKNAME=ICICI&PAYMENTMODE=DC&CHECKSUMHASH=UgTNNLvjnFi/vxElGKstkBHJGbNCWDi%2b9pTnz5PhgpYefo89%2bHfI3fGdmkwhRCjLVKw/CIebMnER62PxVj2p2RDkZCOKXvr3JxOr75/AoLY='
  end
end
