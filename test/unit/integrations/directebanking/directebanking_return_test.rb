# frozen_string_literal: true

require 'test_helper'

class DirectebankingReturnTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_return_is_always_succesful
    r = Directebanking::Return.new("")
    assert r.success?
  end
end
