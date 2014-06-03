require 'test_helper'

class RemotePaypalTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @paypal = Paypal::Notification.new('')
  end

  def tear_down
    OffsitePayments.mode = :test
  end

  def test_raw
    assert_equal "https://www.sandbox.paypal.com/cgi-bin/webscr", Paypal.service_url
    assert_nothing_raised do
      assert_equal false, @paypal.acknowledge
    end
  end

  def test_valid_sender_always_true
    OffsitePayments.mode = :production
    assert @paypal.valid_sender?(nil)
    assert @paypal.valid_sender?('127.0.0.1')
  end
end
