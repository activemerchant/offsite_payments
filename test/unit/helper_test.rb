require 'test_helper'

class HelperTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_mappings_gets_initialized
    helper_klass_without_mappings = Class.new(OffsitePayments::Helper)
    assert_equal Hash.new, helper_klass_without_mappings.mappings
    assert_nothing_raised { helper_klass_without_mappings.new(123,'some_key', :amount => 500) }
  end
end
