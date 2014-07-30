require 'test_helper'

class Paystation3partyModuleTest < Test::Unit::TestCase
  include OffsitePayments

  def test_return
   #assert_raise NoMethodError do
  n = OffsitePayments::Integrations::Paystation3party::Return.new({"ec"=>"91", "em"=>'test', "am"=>100}, {})
  assert (!n.success?)  

  n = OffsitePayments::Integrations::Paystation3party::Return.new({"ec"=>"0", "em"=>'test', "am"=>100}, {})
  assert n.success?
  
  assert_raise OffsitePayments::Integrations::Paystation3party::PaystationIdRequired do
    n = OffsitePayments::Integrations::Paystation3party::Return.new({"ec"=>0, "em"=>'test', "am"=>100}, {:quickLookUp=>true})
  end
  
  assert_raise OffsitePayments::Integrations::Paystation3party::InvalidPaystationNotification do
    n = OffsitePayments::Integrations::Paystation3party::Return.new({}, {})
  end
  
  assert_raise OffsitePayments::Integrations::Paystation3party::InvalidPaystationNotification do
    n = OffsitePayments::Integrations::Paystation3party::Return.new({}, {})
  end

    
  end
end
