require 'test_helper'
require 'remote_test_helper'

class RemoteCheckoutFinlandTest < Test::Unit::TestCase
  include RemoteTestHelper

  def setup
    @stamp = Time.now.to_i.to_s # Unique identifier for the payment with all information
    @stamp2 = (Time.now.to_i+1000).to_s # Unique identifier for the payment with minimal information
    @merchant = fixtures(:checkout_finland)[:merchant]
    @secret = fixtures(:checkout_finland)[:secret]
  end

  def test_valid_payment_page_minimal_fields
    payment_page = submit %(
        <% payment_service_for('#{@stamp}', '#{@merchant}', :service => :checkout_finland, :amount => '200', :currency => 'EUR', :credential2 => '#{@secret}') do |service| %>
          <% service.language = 'FI' %> # Payment page language 2 character ISO code.
          <% service.reference = '123123123' %> # Payment reference number. 20 digits max.
          <% service.content = '1' %> # '1' for normal and '2' for adult payments.
          <% service.delivery_date = '20140110' %> # Delivery date in the form of YYYYMMDD
          <% service.notify_url = 'http://example.org/return' %> # Notify URL
          <% service.reject_url = 'http://example.org/return' %> # Reject URL
          <% service.return_url = 'http://example.org/return' %> # Return URL
          <% service.cancel_return_url = 'http://example.org/return' %> # Cancel URL
        <% end %>
      )

      assert_match(%r(Testi Oy)i, payment_page.body)
      assert_match(%r(Testikuja 1)i, payment_page.body)
      assert_match(%r(12345 Testi)i, payment_page.body)
  end

  def test_valid_payment_page_all_fields
    payment_page = submit %(
        <% payment_service_for('#{@stamp2}', '#{@merchant}', :service => :checkout_finland, :amount => '200', :currency => 'EUR',:credential2 => '#{@secret}') do |service| %>
          <% service.customer :first_name => "Tero", # Optional customer information
            :last_name => 'Testaaja',
            :phone => '0800 552 010',
            :email => 'support@checkout.fi' %>
          <% service.language = 'FI' %>
          <% service.billing_address :address1 => 'Testikatu 1 A 10', # Optional billing address
            :city => 'Helsinki',
            :zip => '00100',
            :country => 'FIN' %>
          <% service.reference = '123123123' %>
          <% service.content = '1' %>
          <% service.delivery_date = '20140110' %>
          <% service.description = 'Remote test items' %>
          <% service.notify_url = 'http://example.org/return' %>
          <% service.reject_url = 'http://example.org/return' %>
          <% service.return_url = 'http://example.org/return' %>
          <% service.cancel_return_url = 'http://example.org/return' %>
        <% end %>
      )

      assert_match(%r(Tero Testaaja)i, payment_page.body)
      assert_match(%r(Testikatu 1 A 10)i, payment_page.body)
      assert_match(%r(Remote test items)i, payment_page.body)
  end

end
