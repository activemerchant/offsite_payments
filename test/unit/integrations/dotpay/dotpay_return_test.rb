require 'test_helper'

class DotpayReturnTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_return_is_always_succesful
    r = Dotpay::Return.new("")
    assert r.success?
  end
end
