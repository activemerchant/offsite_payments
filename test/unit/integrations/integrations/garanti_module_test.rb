require 'test_helper'

class GarantiTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_notification_method
    assert_instance_of Garanti::Notification, Garanti.notification('name=cody')
  end
end
