require 'test_helper'

class PaytmModuleTest < Test::Unit::TestCase
  include OffsitePayments::Integrations


  def setup
  	OffsitePayments.mode = :test
  end



  def test_service_url_in_test_mode
  	OffsitePayments.mode = :test
  	assert Paytm.service_url, Paytm.test_url
  end

  def test_service_url_in_production_mode
  	OffsitePayments.mode = :production
  	assert Paytm.service_url, Paytm.production_url
  end

  def test_service_url_in_invalid_mode
    OffsitePayments.mode = :cool
    assert_raise(StandardError){ Paytm.service_url }
  end




  # def test_helper_method
  #   assert_instance_of Paytm::Helper, Paytm.helper(123, 'account')
  # end

  # def test_notification_method
  #   assert_instance_of Paytm::Notification, Paytm.notification('name=cody')
  # end

  # def test_return_method
  #   assert_instance_of Paytm::Return, Paytm.return('name=cody')
  # end
end

