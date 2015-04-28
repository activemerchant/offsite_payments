require 'test_helper'

class CoinbaseNotificationTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @coinbase = Coinbase::Notification.new(http_raw_data, { :credential1 => "key", :credential2 => "secret" })
  end

  def test_accessors
    assert @coinbase.complete?
    assert_equal "Completed", @coinbase.status
    assert_equal "OQJ836AF", @coinbase.transaction_id
    assert_equal "10", @coinbase.item_id
    assert_equal "0.01", @coinbase.gross
    assert_equal "CAD", @coinbase.currency
    assert_equal 1404914433, @coinbase.received_at
  end

  def test_total_original_support
    coinbase = Coinbase::Notification.new(total_original_http_raw_data, { :credential1 => "key", :credential2 => "secret" })
    assert_equal "0.01", coinbase.gross    
  end

  def test_acknowledgement
    Net::HTTP.any_instance.expects(:request).returns(stub(:body => http_raw_data))
    assert @coinbase.acknowledge
  end

  def test_acknowledgement_with_conflicting_server_response
    Net::HTTP.any_instance.expects(:request).returns(stub(:body => conflicting_http_raw_data))
    assert !@coinbase.acknowledge
  end

  def test_params_with_empty_data
    coinbase = Coinbase::Notification.new('')
    assert_empty coinbase.params
  end

  def test_params_with_invalid_data
    coinbase = Coinbase::Notification.new('{"invalid": json}')
    assert_empty coinbase.params
  end

  def test_acknowledgement_with_empty_data
    Net::HTTP.any_instance.expects(:request).returns(stub(body: ''))
    refute @coinbase.acknowledge
  end

  def test_acknowledgement_with_invalid_data
    Net::HTTP.any_instance.expects(:request).returns(stub(body: '{"invalid": json}'))
    refute @coinbase.acknowledge
  end

  private

  def http_raw_data
    '{"order":{"id":"OQJ836AF","created_at":"2014-07-09T07:00:33-07:00","status":"completed","event":{"type":"completed"},"total_btc":{"cents":1463,"currency_iso":"BTC"},"total_native":{"cents":1,"currency_iso":"CAD"},"total_payout":{"cents":0,"currency_iso":"USD"},"custom":"10","receive_address":"19FuVxoEvVLxRibVnmSciNXEsfgFs8W29Z","button":{"type":"buy_now","name":"Shop One - #10","description":null,"id":"0c3e9c6dd38619a2ba11b4561631e6ad"},"refund_address":"1BmmrdqcLqGCtx54vvencNS8VCMsjJCEBA","transaction":{"id":"53bd4b0e86fd2456d8000003","hash":null,"confirmations":0}}}'
  end

  def conflicting_http_raw_data
    '{"order":{"id":"OQJ836AF","created_at":"2014-07-09T07:00:33-07:00","status":"failed","event":{"type":"completed"},"total_btc":{"cents":1463,"currency_iso":"BTC"},"total_native":{"cents":1,"currency_iso":"CAD"},"total_payout":{"cents":0,"currency_iso":"USD"},"custom":"10","receive_address":"19FuVxoEvVLxRibVnmSciNXEsfgFs8W29Z","button":{"type":"buy_now","name":"Shop One - #10","description":null,"id":"0c3e9c6dd38619a2ba11b4561631e6ad"},"refund_address":"1BmmrdqcLqGCtx54vvencNS8VCMsjJCEBA","transaction":{"id":"53bd4b0e86fd2456d8000003","hash":null,"confirmations":0}}}'
  end
  
  def total_original_http_raw_data
    '{"order":{"id":"OQJ836AF","created_at":"2014-07-09T07:00:33-07:00","status":"completed","event":{"type":"completed"},"total_btc":{"cents":1463,"currency_iso":"BTC"},"total_original":{"cents":1,"currency_iso":"CAD"},"total_payout":{"cents":0,"currency_iso":"USD"},"custom":"10","receive_address":"19FuVxoEvVLxRibVnmSciNXEsfgFs8W29Z","button":{"type":"buy_now","name":"Shop One - #10","description":null,"id":"0c3e9c6dd38619a2ba11b4561631e6ad"},"refund_address":"1BmmrdqcLqGCtx54vvencNS8VCMsjJCEBA","transaction":{"id":"53bd4b0e86fd2456d8000003","hash":null,"confirmations":0}}}'
  end
end
