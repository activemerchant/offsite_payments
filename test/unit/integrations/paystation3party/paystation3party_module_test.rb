require 'test_helper'

class Paystation3partyModuleTest < Test::Unit::TestCase
  include OffsitePayments

  def test_notification_method
    
    assert_raise NoMethodError do
      n = OffsitePayments::Integrations::Paystation3party::Notification.new({})
    end
    
  end
end
