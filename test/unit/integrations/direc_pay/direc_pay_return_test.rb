require 'test_helper'

class DirecPayReturnTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_success
    direc_pay = DirecPay::Return.new(http_raw_data_success)
    assert direc_pay.success?
    assert direc_pay.notification.complete?
    assert_equal 'Completed', direc_pay.message
  end

  def test_failure
    direc_pay = DirecPay::Return.new(http_raw_data_failure)
    refute direc_pay.success?
    refute direc_pay.notification.complete?
    assert_equal 'Failed', direc_pay.message
    assert_equal 'Failed', direc_pay.notification.status
  end

  def test_return_has_notification
    direc_pay = DirecPay::Return.new(http_raw_data_success)
    notification = direc_pay.notification

    assert_equal '1001010000026481', direc_pay.notification.transaction_id
    assert notification.complete?
    assert_equal 'Completed', notification.status
    assert_equal '1001', notification.item_id
    assert_equal '1.00', notification.gross
    assert_equal 100, notification.gross_cents
    assert_equal Money.from_amount(1.00, 'INR'), notification.amount
    assert_equal 'INR', notification.currency
    assert_equal 'IND', notification.country
    assert_equal 'NULL', notification.other_details
  end

  private

  def http_raw_data_success
    "responseparams=1001010000026481|SUCCESS|IND|INR|NULL|1001|1.00|"
  end

  def http_raw_data_failure
    "responseparams=1001010000026516|FAIL|IND|INR|NULL|1001|1.00|"
  end

end
