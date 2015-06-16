require 'test_helper'

class RemotePaytmTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @paytm = Paytm::Notification.new(http_raw_data, :credential1 => 'WorldP64425807474247', :credential2 => 'kbzk1DSbJiV_O3p5', :credential3 => 'Retail', :credential4 => 'worldpressplg')
  end

  def test_raw
    OffsitePayments.mode = :production
    assert_equal "https://secure.paytm.in/oltp-web/processTransaction", Paytm.service_url

    OffsitePayments.mode = :test
    assert_equal "https://pguat.paytm.com/oltp-web/processTransaction", Paytm.service_url

    assert_nothing_raised do
      assert @paytm.checksum_ok?
    end
  end

  private
  def http_raw_data
   "MID=WorldP64425807474247&ORDER_ID=100PT012&CUST_ID=test@example.com&INDUSTRY_TYPE_ID=Retail&CHANNEL_ID=WEB&TXN_AMOUNT=10&WEBSITE=worldpressplg&MOBILE_NO=9999999999&EMAIL=test@example.com&CHECKSUMHASH=CeSZKawwkFriBwTYbGjwOSHQDNU2aR/69y0D+75aIOaN+1ivD/vn2gXiOpCR3XMSVIw0EZQG23X0x5dVt1OQwJEkvrUWLJ4MpprD3XL07KI="
  end
end
