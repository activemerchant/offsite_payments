require 'test_helper'
require 'remote_test_helper'
require 'nokogiri'

class RemoteValitorTest < Test::Unit::TestCase
  include RemoteTestHelper

  def setup
    ::WebMock.allow_net_connect!
    @order = "order#{generate_unique_id}"
    @login = fixtures(:valitor)[:login]
    @password = fixtures(:valitor)[:password]
  end

  # def test_full_purchase
  #   notification_request = listen_for_notification(80) do |notify_url|
  #     payment_page = submit %(
  #       <% payment_service_for('#{@order}', '#{@login}', :service => :valitor, :credential2 => 'Testing', :html => {:method => 'GET'}) do |service| %>
  #         <% service.product(1, :amount => 100, :description => 'PRODUCT1', :discount => '0') %>
  #         <% service.return_url = 'http://example.org/return' %>
  #         <% service.cancel_return_url = 'http://example.org/cancel' %>
  #         <% service.notify_url = '#{notify_url}' %>
  #         <% service.success_text = 'SuccessText!' %>
  #         <% service.language = 'EN' %>
  #       <% end %>
  #     )

  #     assert_match(%r(http://example.org/cancel)i, payment_page.body)
  #     assert_match(%r(PRODUCT1), payment_page.body)

  #     form = payment_page.forms.first
  #     form['tbKortnumer'] = '4111111111111111'
  #     form['drpGildistimiManudur'] = '12'
  #     form['drpGildistimiAr'] = Time.now.year
  #     form['tbOryggisnumer'] = '000'
  #     result_page = form.submit(form.submits.first)

  #     assert continue_link = result_page.links.detect{|e| e.text =~ /successtext!/i}
  #     assert_match(%r(^http://example.org/return\?)i, continue_link.href)

  #     check_common_fields(return_from(continue_link.href))
  #   end

  #   check_common_fields(notification_from(notification_request))
  # end

  def test_customer_fields
    payment_page = submit %(
      <% payment_service_for('#{@order}', '#{@login}', :service => :valitor, :credential2 => '#{@password}', :html => {:method => 'GET'}) do |service| %>
        <% service.product(1, :amount => 100, :description => 'test', :discount => '0') %>
        <% service.return_url = 'http://example.org/return' %>
        <% service.cancel_return_url = 'http://example.org/cancel' %>
        <% service.success_text = 'SuccessText!' %>
        <% service.language = 'EN' %>
        <% service.collect_customer_info %>
      <% end %>
    )

    form = payment_page.forms.first
    form['ctl00$ContentPlaceHolder1$txtKortnumer'] = '9999999999999999'
    form['ctl00$ContentPlaceHolder1$ddlGildistimiManudur'] = '12'
    form['ctl00$ContentPlaceHolder1$ddlGildistimiAr'] = Time.now.year
    form['ctl00$ContentPlaceHolder1$txtOryggisnumer'] = '111'
    form['ctl00$ContentPlaceHolder1$txtNafn'] = "NAME"
    form['ctl00$ContentPlaceHolder1$txtHeimilisfang'] = "123 ADDRESS"
    form['ctl00$ContentPlaceHolder1$txtPostnumer'] = "98765"
    form['ctl00$ContentPlaceHolder1$txtStadur'] = "CITY"
    form['ctl00$ContentPlaceHolder1$txtLand'] = "COUNTRY"
    form['ctl00$ContentPlaceHolder1$txtNetfang'] = "EMAIL@EXAMPLE.COM"
    form['ctl00$ContentPlaceHolder1$txtAthugasemdir'] = "COMMENTS"
    final_page = form.submit(form.submits.last)

    assert continue_link = final_page.links.detect{|e| e.text =~ /SuccessText!/i}
    assert_match(%r(^http://example.org/return\?)i, continue_link.href)

    ret = return_from(continue_link.href)
    check_common_fields(ret)
    assert_equal "NAME", ret.customer_name
    assert_equal "123 ADDRESS", ret.customer_address
    assert_equal "98765", ret.customer_zip
    assert_equal "CITY", ret.customer_city
    assert_equal "COUNTRY", ret.customer_country
    assert_equal "EMAIL@EXAMPLE.COM", ret.customer_email
    assert_equal "COMMENTS", ret.customer_comment
  end

  def test_products
    payment_page = submit %(
      <% payment_service_for('#{@order}', '#{@login}', :service => :valitor, :credential2 => #{@password}, :html => {:method => 'GET'}) do |service| %>
        <% service.product(1, :amount => 100, :description => 'PRODUCT1') %>
        <% service.product(2, :amount => 200, :description => 'PRODUCT2', :discount => '50') %>
        <% service.product(3, :amount => 300, :description => 'PRODUCT3', :quantity => '6') %>
        <% service.return_url = 'http://example.org/return' %>
        <% service.cancel_return_url = 'http://example.org/cancel' %>
        <% service.success_text = 'SuccessText!' %>
        <% service.language = 'EN' %>
        <% service.collect_customer_info %>
      <% end %>
    )

    # assert_match(%r(http://example.org/cancel)i, payment_page.body)

    doc = Nokogiri::HTML(payment_page.body)
    rows = doc.css("div.product_items")
    assert_equal 3, rows.size
    check_product_row(rows[0], "PRODUCT1", "1", "100 ISK", "0 ISK",  "100 ISK")
    check_product_row(rows[1], "PRODUCT2", "1", "200 ISK", "50 ISK", "150 ISK")
    check_product_row(rows[2], "PRODUCT3", "6", "300 ISK", "0 ISK",  "1.800 ISK")
    assert_match /2.050 ISK/, doc.css('div.total_price').text
  end

  def test_default_product_if_none_provided
    payment_page = submit %(
      <% payment_service_for('#{@order}', '#{@login}', :service => :valitor, :credential2 => #{@password}, :amount => 100, :html => {:method => 'GET'}) do |service| %>
        <% service.return_url = 'http://example.org/return' %>
        <% service.cancel_return_url = 'http://example.org/cancel' %>
        <% service.success_text = 'SuccessText!' %>
        <% service.language = 'EN' %>
        <% service.collect_customer_info %>
      <% end %>
    )

    # assert_match(%r(http://example.org/cancel)i, payment_page.body)

    doc = Nokogiri::HTML(payment_page.body)
    rows = doc.css("div.product_items")
    assert_equal 1, rows.size
    check_product_row(rows[0], @order, "1", "100 ISK", "0 ISK",  "100 ISK")
    assert_match /100 ISK/, doc.css('div.total_price').text
  end

  def check_product_row(row, desc, quantity, amount, discount, total)
    assert_equal desc,     row.element_children[0].text.strip
    assert_equal quantity, row.element_children[1].text.strip
    assert_equal amount,   row.element_children[2].text.strip
    assert_equal discount, row.element_children[3].text.strip
    assert_equal total,    row.element_children[4].text.strip
  end

  def check_common_fields(response)
    assert response.success?
    assert_equal 'Mastercard', response.card_type
    assert_equal '9999', response.card_last_four
    assert_equal @order, response.order
    assert response.received_at.to_s.length > 0
    assert response.authorization_number.length > 0
    assert response.transaction_number.length > 0
    assert response.transaction_id.length > 0
  end

  def return_from(uri)
    OffsitePayments::Integrations::Valitor.return(uri.split('?').last, :credential2 => @password)
  end

  # def notification_from(request)
  #   OffsitePayments::Integrations::Valitor.notification(request.params["QUERY_STRING"], :credential2 => @password)
  # end
end
