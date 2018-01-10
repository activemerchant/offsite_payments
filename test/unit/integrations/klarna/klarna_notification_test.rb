require 'test_helper'

class KlarnaNotificationTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @options = {:authorization_header => authorization_header, :credential2 => 'Example shared secret', :query_string => 'order=123'}
    @klarna = Klarna::Notification.new(request_body, @options)
  end

  def test_accessors
    assert @klarna.complete?
    assert_equal "Completed", @klarna.status
    assert_equal "d9252c4a-15ed-40c1-8abb-8bb9e253bbd1", @klarna.transaction_id
    assert_equal "123", @klarna.item_id
    assert_equal "50.00", @klarna.gross
    assert_equal "SEK", @klarna.currency
  end

  def test_x2ness_of_gross_amount
    @klarna.stubs(gross_cents: 100)

    assert_equal '1.00', @klarna.gross
  end

  def test_compositions
    assert_equal Money.from_amount(50.00, 'SEK'), @klarna.amount
  end

  def test_acknowledge
    @klarna = Klarna::Notification.new(request_body, @options)

    assert @klarna.acknowledge
  end

  def test_invalid_acknowledgement
    @options[:authorization_header] = 'not a valid verification header'
    @klarna = Klarna::Notification.new(request_body, @options)

    assert !@klarna.acknowledge
  end

  private

  def authorization_header
    'Klarna YQx3lle1SWF9kGH6WuyQR0X+O1YpCPOxKbCpa+l8MTU='
  end

  def request_body
    "{\"checkout_token\":\"abcd123\",\"merchant_base_uri\":\"http://klarna-testing.com/cart\",\"merchant_checkout_uri\":\"http://klarna-testing.com/cart\",\"merchant_confirmation_uri\":\"https://klarna-testing.com/services/ping/notify_integration/klarna/1234?order=1234\",\"merchant_id\":\"N11111\",\"merchant_terms_uri\":\"http://klarna-testing.com/cart\",\"order_amount\":5000,\"purchase_currency\":\"SEK\",\"reference\":\"d9252c4a-15ed-40c1-8abb-8bb9e253bbd1\",\"status\":\"checkout_complete\"}"
  end
end
