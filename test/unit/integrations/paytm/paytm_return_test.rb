require 'test_helper'

class PaytmReturnTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @paytm = Paytm::Return.new(http_raw_data_success, credential1: 'WorldP64425807474247', credential2: 'kbzk1DSbJiV_O3p5', credential3: 'Retail', credential4: 'worldpressplg')
  end

  def setup_failed_return
    @paytm = Paytm::Return.new(http_raw_data_failure, credential1: 'WorldP64425807474247', credential2: 'kbzk1DSbJiV_O3p5', credential3: 'Retail', credential4: 'worldpressplg')
  end

  def test_success
    assert @paytm.success?
    assert_equal 'Completed', @paytm.status('100PT012', '10')
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
    assert notification.amount_ok?(BigDecimal.new('10.00'))
    assert_equal 'TXN_SUCCESS', notification.transaction_status
    assert_equal '494157', @paytm.notification.transaction_id
    assert_equal 'CC', @paytm.notification.type
    assert_equal 'INR', notification.currency
    assert_equal '100PT012', notification.invoice
    assert_equal 'WorldP64425807474247', notification.account
    assert_equal '10.00', notification.gross
    assert_equal 'M9E4OLugj4L3TLLiof2BSO03hhQQLMucnVgtYuHi4wIVLB20dCXS632PRw0dTmnAa58R0kEuh9+V3bfQs4F/SrlmsmV+hvhb3Nui1zlnh/o=', notification.checksum
    assert notification.checksum_ok?
  end

  private

  def http_raw_data_success
    'MID=WorldP64425807474247&ORDERID=100PT012&TXNAMOUNT=10&CURRENCY=INR&TXNID=494157&BANKTXNID=201512236592678&STATUS=TXN_SUCCESS&RESPCODE=01&RESPMSG=Txn+Successful&TXNDATE=2015-12-23 16:06:22.0&GATEWAYNAME=ICICI&BANKNAME=ICICI&PAYMENTMODE=CC&MERC_UNQ_REF=100PT012&CHECKSUMHASH=M9E4OLugj4L3TLLiof2BSO03hhQQLMucnVgtYuHi4wIVLB20dCXS632PRw0dTmnAa58R0kEuh9%2bV3bfQs4F/SrlmsmV%2bhvhb3Nui1zlnh/o='
  end

  def http_raw_data_failure
    'MID=WorldP64425807474247&ORDERID=100PT012&TXNAMOUNT=10&CURRENCY=INR&TXNID=494157&BANKTXNID=201512236592678&TXNDATE=2015-12-23 16:06:22.0&GATEWAYNAME=ICICI&BANKNAME=ICICI&PAYMENTMODE=CC&MERC_UNQ_REF=100PT012&STATUS=TXN_FAILURE&RESPCODE=330&RESPMSG=Invalid+Checksum&CHECKSUMHASH=x6FmPuyiHDCZ4dI4ffflLEDhngj8zuf6CVgrkpZEkmxfLw22coNvru8H1xZztSKUQeF7qsnR5aC/O36m%2bam6sDLXN9eqSdl7%2bNhe8kp9qFs='
  end

  def checksum
    'M9E4OLugj4L3TLLiof2BSO03hhQQLMucnVgtYuHi4wIVLB20dCXS632PRw0dTmnAa58R0kEuh9%2bV3bfQs4F/SrlmsmV%2bhvhb3Nui1zlnh/o='
  end
end
