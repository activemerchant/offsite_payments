require 'test_helper'
require 'remote_test_helper'

class RemoteGoCoinTest < Test::Unit::TestCase
  include RemoteTestHelper

  def setup
    @auth_token = fixtures(:go_coin)[:auth_token]
    @merchant_id = fixtures(:go_coin)[:merchant_id]
  end

  def test_invoice_id_properly_generated
    helper = OffsitePayments::Integrations::GoCoin::Helper.new(123, @merchant_id, :amount => 10, :account_name => @merchant_id, :authcode => @auth_token)
    assert helper.form_fields['invoice_id']
  end 

end