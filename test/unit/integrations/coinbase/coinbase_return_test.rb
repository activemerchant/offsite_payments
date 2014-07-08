require 'test_helper'

class CoinbaseReturnTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    Net::HTTP.any_instance.expects(:request).returns(stub(:body => http_raw_data))
    @coinbase = Coinbase::Return.new(query_string, { :credential1 => "key", :credential2 => "secret" })
  end

  def test_valid_return
    assert @coinbase.success?
  end

  private

  def http_raw_data
    '{"order":{"id":"ABC123","custom":"test123","created_at":"1970-01-01T00:00:00Z","total_native":{"cents":100,"currency_iso":"USD"},"status":"completed"}}'
  end

  def query_string
    'utm_nooverride=1&order%5Bbutton%5D%5Bdescription%5D=&order%5Bbutton%5D%5Bid%5D=8c6a828cb45cab00706f7a159f1a52f9&order%5Bbutton%5D%5Bname%5D=Shop+One+-+%2328&order%5Bbutton%5D%5Btype%5D=buy_now&order%5Bcreated_at%5D=2014-07-07+13%3A29%3A00+-0700&order%5Bcustom%5D=28&order%5Bevent%5D=&order%5Bid%5D=2UFE1P1H&order%5Breceive_address%5D=1HdL4ZtdLjLWTbiEjyisJ9z1L3jrZmi5Xg&order%5Brefund_address%5D=16RgHcXM5yddT8uaL28hWkJeS7dz2Ry3AB&order%5Bstatus%5D=completed&order%5Btotal_btc%5D%5Bcents%5D=16104&order%5Btotal_btc%5D%5Bcurrency_iso%5D=BTC&order%5Btotal_native%5D%5Bcents%5D=11&order%5Btotal_native%5D%5Bcurrency_iso%5D=CAD&order%5Btotal_payout%5D%5Bcents%5D=0&order%5Btotal_payout%5D%5Bcurrency_iso%5D=USD&order%5Btransaction%5D%5Bconfirmations%5D=0&order%5Btransaction%5D%5Bhash%5D=&order%5Btransaction%5D%5Bid%5D=53bb031089cb0d0cad000005'
  end
end
