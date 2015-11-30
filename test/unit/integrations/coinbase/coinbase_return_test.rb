require 'test_helper'

class CoinbaseReturnTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @options = { :credential1 => "key", :credential2 => "secret" }
  end

  def test_valid_return
    Net::HTTP.any_instance.expects(:request).returns(stub(:body => valid_http_raw_data))
    coinbase_return = Coinbase::Return.new(valid_query_string, @options)

    assert coinbase_return.notification.acknowledge
    assert coinbase_return.success?
  end

  def test_invalid_return
    Net::HTTP.any_instance.expects(:request).returns(stub(:body => valid_http_raw_data))
    coinbase_return = Coinbase::Return.new(invalid_query_string, @options)

    assert !coinbase_return.notification.acknowledge
    assert coinbase_return.success?
  end

  def test_catch_nil_params
    Net::HTTP.any_instance.expects(:request).returns(stub(:body => http_raw_data_missing_order_key))
    coinbase_return = Coinbase::Return.new(valid_query_string, @options)

    assert !coinbase_return.notification.acknowledge
    assert coinbase_return.success?
  end

  private

  def valid_http_raw_data
    '{"order":{"id":"OQJ836AF","created_at":"2014-07-09T07:00:33-07:00","status":"completed","event":{"type":"completed"},"total_btc":{"cents":1463,"currency_iso":"BTC"},"total_native":{"cents":1,"currency_iso":"CAD"},"total_payout":{"cents":0,"currency_iso":"USD"},"custom":"10","receive_address":"19FuVxoEvVLxRibVnmSciNXEsfgFs8W29Z","button":{"type":"buy_now","name":"Shop One - #10","description":null,"id":"0c3e9c6dd38619a2ba11b4561631e6ad"},"refund_address":"1BmmrdqcLqGCtx54vvencNS8VCMsjJCEBA","transaction":{"id":"53bd4b0e86fd2456d8000003","hash":null,"confirmations":0}}}'
  end

  def http_raw_data_missing_order_key
    JSON.parse(valid_http_raw_data).reject { |key, value| key == 'order' }.to_json
  end

  def valid_query_string
    'utm_nooverride=1&order%5Bbutton%5D%5Bdescription%5D=&order%5Bbutton%5D%5Bid%5D=0c3e9c6dd38619a2ba11b4561631e6ad&order%5Bbutton%5D%5Bname%5D=Shop+One+-+%2310&order%5Bbutton%5D%5Btype%5D=buy_now&order%5Bcreated_at%5D=2014-07-09+07%3A00%3A33+-0700&order%5Bcustom%5D=10&order%5Bevent%5D=&order%5Bid%5D=OQJ836AF&order%5Breceive_address%5D=19FuVxoEvVLxRibVnmSciNXEsfgFs8W29Z&order%5Brefund_address%5D=1BmmrdqcLqGCtx54vvencNS8VCMsjJCEBA&order%5Bstatus%5D=completed&order%5Btotal_btc%5D%5Bcents%5D=1463&order%5Btotal_btc%5D%5Bcurrency_iso%5D=BTC&order%5Btotal_native%5D%5Bcents%5D=1&order%5Btotal_native%5D%5Bcurrency_iso%5D=CAD&order%5Btotal_payout%5D%5Bcents%5D=0&order%5Btotal_payout%5D%5Bcurrency_iso%5D=USD&order%5Btransaction%5D%5Bconfirmations%5D=0&order%5Btransaction%5D%5Bhash%5D=&order%5Btransaction%5D%5Bid%5D=53bd4b0e86fd2456d8000003'
  end

  def invalid_query_string
    'utm_nooverride=1&order%5Bbutton%5D%5Bdescription%5D=&order%5Bbutton%5D%5Bid%5D=0c3e9c6dd38619a2ba11b4561631e6ad&order%5Bbutton%5D%5Bname%5D=Shop+One+-+%2310&order%5Bbutton%5D%5Btype%5D=buy_now&order%5Bcreated_at%5D=2014-07-09+07%3A00%3A33+-0700&order%5Bcustom%5D=10&order%5Bevent%5D=&order%5Bid%5D=OQJ836AF&order%5Breceive_address%5D=19FuVxoEvVLxRibVnmSciNXEsfgFs8W29Z&order%5Brefund_address%5D=1BmmrdqcLqGCtx54vvencNS8VCMsjJCEBA&order%5Bstatus%5D=failed&order%5Btotal_btc%5D%5Bcents%5D=1463&order%5Btotal_btc%5D%5Bcurrency_iso%5D=BTC&order%5Btotal_native%5D%5Bcents%5D=1&order%5Btotal_native%5D%5Bcurrency_iso%5D=CAD&order%5Btotal_payout%5D%5Bcents%5D=0&order%5Btotal_payout%5D%5Bcurrency_iso%5D=USD&order%5Btransaction%5D%5Bconfirmations%5D=0&order%5Btransaction%5D%5Bhash%5D=&order%5Btransaction%5D%5Bid%5D=53bd4b0e86fd2456d8000003'
  end

end
