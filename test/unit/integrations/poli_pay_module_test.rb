require 'test_helper'

class PoliPayModuleTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_token_url
    token = '6MIP8TMf1zwNfTnO2nx1+uq5Xd/6S7FN' # + to test escaping
    assert_equal "#{PoliPay::Interface.base_url}/Transaction/GetTransaction?token="+
                 '6MIP8TMf1zwNfTnO2nx1%2Buq5Xd%2F6S7FN',
                 PoliPay::QueryInterface.url(token)
  end

end
