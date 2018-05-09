require 'test_helper'

class MollieCreditcardModuleTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_notification_method
    assert_instance_of MollieCreditcard::Notification, MollieCreditcard.notification("id=482d599bbcc7795727650330ad65fe9b", :credential1 => '1234567')
  end

  def test_return_method
    assert_instance_of MollieCreditcard::Return, MollieCreditcard.return("", :credential1 => '1234567')
  end

  def test_live?
    OffsitePayments.stubs(:mode).returns(:development)
    assert !MollieCreditcard.live?

    OffsitePayments.stubs(:mode).returns(:production)
    assert MollieCreditcard.live?
  end
end
