require 'test_helper'
require 'remote_test_helper'

class RemoteBitPayTest < Test::Unit::TestCase
  include RemoteTestHelper

  def setup
    @api_key = fixtures(:bit_pay)[:api_key]
  end

  def test_invoice_id_properly_generated
    helper = OffsitePayments::Integrations::BitPay::Helper.new(123, @api_key, :amount => 100, :currency => 'USD')
    assert helper.form_fields["id"]
  end

end
