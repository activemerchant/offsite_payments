require 'test_helper'

class PaytmNotificationTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @paytm = Paytm::Notification.new(http_raw_data, :credential1 => 'WorldP64425807474247', :credential2 => 'kbzk1DSbJiV_O3p5', :credential3 => 'Retail', :credential4 => 'worldpressplg')
  end

  def test_accessors
    assert @paytm.complete?
    assert_equal "Completed", @paytm.status
    assert_equal "100PT012", @paytm.transaction_id
    assert_equal "TXN_SUCCESS", @paytm.transaction_status
    assert_equal "10", @paytm.gross
    assert_equal "INR", @paytm.currency
    assert_equal true, @paytm.invoice_ok?('100PT012')
    assert_equal true, @paytm.amount_ok?(BigDecimal.new('10.00'),BigDecimal.new('0.00'))
    assert_equal "CC", @paytm.type
    assert_equal "100PT012", @paytm.invoice
    assert_equal "WorldP64425807474247", @paytm.account
    assert_equal "0.00", @paytm.discount
    assert_equal "test@example.com", @paytm.customer_email
    assert_equal "9999999999", @paytm.customer_phone
    assert_equal "paytm-Admin", @paytm.customer_first_name
    assert_equal "", @paytm.customer_last_name
    assert_equal "CeSZKawwkFriBwTYbGjwOSHQDNU2aR/69y0D+75aIOaN+1ivD/vn2gXiOpCR3XMSVIw0EZQG23X0x5dVt1OQwJEkvrUWLJ4MpprD3XL07KI=", @paytm.checksum
    #assert_equal "E000", @paytm.message
    assert_equal true, @paytm.checksum_ok?
  end

  def test_compositions
    assert_equal '10.00', @paytm.gross
  end

  def test_acknowledgement
    assert @paytm.acknowledge
  end

  private
  def http_raw_data
   "MID=WorldP64425807474247&ORDER_ID=100PT012&CUST_ID=test@example.com&INDUSTRY_TYPE_ID=Retail&CHANNEL_ID=WEB&TXN_AMOUNT=10&WEBSITE=worldpressplg&MOBILE_NO=9999999999&EMAIL=test@example.com&CHECKSUMHASH=CeSZKawwkFriBwTYbGjwOSHQDNU2aR/69y0D+75aIOaN+1ivD/vn2gXiOpCR3XMSVIw0EZQG23X0x5dVt1OQwJEkvrUWLJ4MpprD3XL07KI="
  end
end
