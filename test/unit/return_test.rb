require 'test_helper'

class ReturnTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_return
    r = Return.new('')
    assert r.success?
  end
end
