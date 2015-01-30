require 'test_helper'

class MollieMistercashModuleTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_notification_method
    assert_instance_of MollieMistercash::Notification, MollieMistercash.notification("id=482d599bbcc7795727650330ad65fe9b", :credential1 => '1234567')
  end

  def test_return_method
    assert_instance_of MollieMistercash::Return, MollieMistercash.return("", :credential1 => '1234567')
  end

  def test_live?
    OffsitePayments.stubs(:mode).returns(:development)
    assert !MollieMistercash.live?

    OffsitePayments.stubs(:mode).returns(:production)
    assert MollieMistercash.live?
  end
end
