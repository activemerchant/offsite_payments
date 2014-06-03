require 'test_helper'

class RemoteQuickPayTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @quickpay = Quickpay::Notification.new('')
  end

  def tear_down
    OffsitePayments.mode = :test
  end

  def test_raw
    assert_equal "https://secure.quickpay.dk/form/", Quickpay.service_url
    assert_nothing_raised do
      assert_equal false, @quickpay.acknowledge
    end
  end

  def test_valid_sender_always_true
    OffsitePayments.mode = :production
    assert @quickpay.valid_sender?(nil)
    assert @quickpay.valid_sender?('127.0.0.1')
  end
end
