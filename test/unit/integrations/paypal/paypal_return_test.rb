require 'test_helper'

class PaypalReturnTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_return
    r = Paypal::Return.new('')
    assert r.success?
  end
end
