require 'test_helper'

class PesopayReturnTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_valid_return
    r = Pesopay::Return.new('Ref=1')
    assert r.success?
  end

  def test_invalid_return
    r = Pesopay::Return.new('')
    assert !r.success?
  end

end
