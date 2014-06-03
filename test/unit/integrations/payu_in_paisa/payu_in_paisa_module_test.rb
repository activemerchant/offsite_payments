require 'test_helper'

class PayuInPaisaModuleTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    OffsitePayments.mode = :test
  end

  def test_service_url_method
    OffsitePayments.mode = :test
    assert_equal "https://test.payu.in/_payment.php", PayuInPaisa.service_url

    OffsitePayments.mode = :production
    assert_equal "https://secure.payu.in/_payment.php", PayuInPaisa.service_url
  ensure
    OffsitePayments.mode = :test
  end

  def test_return_method
    assert_instance_of PayuInPaisa::Return, PayuInPaisa.return('name=foo', {})
  end

  def test_notification_method
    assert_instance_of PayuInPaisa::Notification, PayuInPaisa.notification('name=foo', {})
  end
end
