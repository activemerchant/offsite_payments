require 'test_helper'
require 'remote_test_helper'

class RemoteMolpayTest < Test::Unit::TestCase
  include RemoteTestHelper

  def setup
    @account = "molpaytech"
    @amount = "1.10"
    @order = "Order-1.10"
    @currency = "MYR"
    @credential = "MOLPAY_VERIFICATION_KEY"
  end

  def test_valid_payment_page
    payment_page = submit %(
        <% payment_service_for('#{@order}', '#{@account}', :service => :molpay, :amount => #{@amount}, :currency => '#{@currency}', :credential2 => '#{@credential}') do |service| %>
          <% service.return_url = 'http://example.org/return' %>
          <% service.description = 'Purchase of #{@order}' %>
        <% end %>
      )

      assert_match(%r(http://example.org/return)i, payment_page.body)
      assert_match(%r(Purchase of #{@order})i, payment_page.body)
      assert_match(%r(#{@order})i, payment_page.body)
      assert_match(%r(#{@amount})i, payment_page.body)
      assert_match(%r(#{@account})i, payment_page.body)
      assert_match(%r(#{@currency})i, payment_page.body)
  end
end
