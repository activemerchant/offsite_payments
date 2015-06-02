require 'test_helper'

class SiampayReturnTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_valid_return
    r = Siampay::Return.new('Ref=1')
    assert r.success?
  end

  def test_invalid_return
    r = Siampay::Return.new('')
    assert !r.success?
  end

end
