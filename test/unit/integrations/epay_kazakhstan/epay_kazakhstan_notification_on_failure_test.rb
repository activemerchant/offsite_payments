class EpayKazakhstanNotificationOnFailureTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    EpayKazakhstan.configure do |config|
      config.merchant_certificate_id = '00C182B189'
      config.merchant_name = 'Test shop'
      config.private_key_pass = 'nissan'
      config.merchant_id = '92061101'
      config.cert_file_path = File.expand_path('../kkbca.cer', __FILE__)
      config.private_key_path = File.expand_path('../test_prv.pem', __FILE__)
    end
    @notification = EpayKazakhstan.notification(http_raw_data)
  end

  def test_has_error?
    assert_equal @notification.has_error?, true
  end

  def test_error
    error = @notification.error
    assert_equal error.type, "system"
    assert error.time == Time.parse("21.01.2001 21:12:60")
    assert_equal error.code, "00"
    assert_equal error.message, "Error Message"
  end

  private

  def http_raw_data
    {
      'response' => '<response order_id="123456"><error type="system" time="21.01.2001 21:12:60" code="00">Error Message</error><session id="1234654656545"/></response>'
    }
  end
end