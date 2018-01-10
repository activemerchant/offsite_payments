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
    'MID=WorldP64425807474247&ORDERID=100PT012&TXNAMOUNT=10&CURRENCY=INR&TXNID=494157&BANKTXNID=201512236592678&STATUS=TXN_SUCCESS&RESPCODE=01&RESPMSG=Txn Successful&TXNDATE=2015-12-23 16:06:22.0&GATEWAYNAME=ICICI&BANKNAME=ICICI&PAYMENTMODE=CC&MERC_UNQ_REF=100PT012&CHECKSUMHASH=M9E4OLugj4L3TLLiof2BSO03hhQQLMucnVgtYuHi4wIVLB20dCXS632PRw0dTmnAa58R0kEuh9+V3bfQs4F/SrlmsmV+hvhb3Nui1zlnh/o='
  end
end
