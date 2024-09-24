require 'test_helper'

class FirstDataModuleTest < Test::Unit::TestCase
  include ActionViewHelperTestHelper
  include OffsitePayments::Integrations

  def test_notification_method
    assert_instance_of FirstData::Notification, FirstData.notification('name=cody')
  end

  def test_address2
    payment_service_for('44','8wd65QS', :service => :first_data,  :amount => 157.0) do |service|
      service.billing_address :address1 => 'address1', :address2 => 'line 2'
    end
    assert hidden_field_set 'x_address', 'address1 line 2'
  end

  def test_lots_of_line_items_same_name
    payment_service_for('44','8wd65QS', :service => :first_data,  :amount => 157.0) do |service|
      35.times{service.add_line_item :name => 'beauty2 - ayoyo', :quantity => 1, :unit_price => 0}
    end
    assert_match(/ more unshown items after this one/, @output_buffer)

    # It should display them all in, despite each having the same name.
    assert(@output_buffer.to_s.scan(/beauty2 - ayoyo/).length > 5)
  end

  def test_lots_of_line_items_different_names
    payment_service_for('44','8wd65QS', :service => :first_data,  :amount => 157.0) do |service|
      35.times{|n| service.add_line_item :name => 'beauty2 - ayoyo' + n.to_s, :quantity => 1, :unit_price => 0}
    end
    assert_match(/ ayoyo3/, @output_buffer)
    assert_match(/ ayoyo4/, @output_buffer)
  end

  def test_should_round_numbers
    payment_service_for('44','8wd65QS', :service => :first_data, :amount => "157.003"){}
    assert_no_match(/x_amount.*157.003"/, @output_buffer)
    payment_service_for('44','8wd65QS', :service => :first_data, :amount => "157.005"){}
    assert_match(/x_amount.*157.01"/, @output_buffer)
  end

  def test_all_fields
    payment_service_for('44','8wd65QS', :service => :first_data,  :amount => 157.0) do |service|
       service.setup_hash :transaction_key => '8CP6zJ7uD875J6tY',
                          :order_timestamp => 1206836763
       service.customer_id 8
       service.customer :first_name => 'g',
                        :last_name => 'g',
                        :email => 'g@g.com',
                        :phone => '3'

      service.billing_address :zip => 'g',
                              :country => 'United States of America',
                              :address1 => 'g'

      service.ship_to_address :first_name => 'g',
                              :last_name => 'g',
                              :city => '',
                              :address1 => 'g',
                              :address2 => '',
                              :state => 'ut',
                              :country => 'United States of America',
                              :zip => 'g'

      service.invoice "516428355"
      service.notify_url "http://t/first_data/payment_received_notification_sub_step"
      service.payment_header 'MyFavoritePal'
      service.add_line_item :name => 'beauty2 - ayoyo', :quantity => 1, :unit_price => 0.0
      service.test_request 'true'
      service.shipping '25.0'
      service.add_shipping_as_line_item
    end

    assert hidden_field_set 'x_cust_id', '8'
    assert hidden_field_set 'x_ship_to_last_name', 'g'
    assert hidden_field_set 'x_fp_timestamp', '1206836763'
    assert hidden_field_set 'x_ship_to_first_name', 'g'
    assert hidden_field_set 'x_last_name', 'g'
    assert hidden_field_set 'x_amount', '157.0'
    assert hidden_field_set 'x_ship_to_country', 'United States of America'
    assert hidden_field_set 'x_ship_to_zip', 'g'
    assert hidden_field_set 'x_zip', 'g'
    assert hidden_field_set 'x_country', 'United States of America'
    assert hidden_field_set 'x_duplicate_window', '28800'
    assert hidden_field_set 'x_relay_response', 'TRUE'
    assert hidden_field_set 'x_ship_to_address', 'g'
    assert hidden_field_set 'x_first_name', 'g'
    assert hidden_field_set 'x_version', '3.1'
    assert hidden_field_set 'x_invoice_num', '516428355'
    assert hidden_field_set 'x_address', 'g'
    assert hidden_field_set 'x_login', '8wd65QS'
    assert hidden_field_set 'x_phone', '3'
    assert hidden_field_set 'x_relay_url', 'http://t/first_data/payment_received_notification_sub_step'
    assert hidden_field_set 'x_fp_sequence', '44'
    assert hidden_field_set 'x_show_form', 'PAYMENT_FORM'
    assert hidden_field_set 'x_header_html_payment_form', 'MyFavoritePal'
    assert hidden_field_set 'x_email', 'g@g.com'
    assert hidden_field_set 'x_fp_hash', '31d572da4e9910b36e999d73925eb01c'
    assert hidden_field_set 'x_test_request', 'true'
    assert hidden_field_set 'x_freight', '25.0'
    assert hidden_field_set 'x_line_item', 'Item 1<|>beauty2 - ayoyo<|>beauty2 - ayoyo<|>1<|>0.0<|>N'
    assert hidden_field_set 'x_line_item', 'Shipping<|>Shipping and Handling Cost<|>Shipping and Handling Cost<|>1<|>25.0<|>N'
  end

  def test_custom
    payment_service_for('44','8wd65QS', :service => :first_data,  :amount => 157.0) do |service|
      service.add_custom_field 'abc', 'def'
    end

    assert hidden_field_set('abc', 'def')
  end

  def test_shipping_and_tax_line_item
    payment_service_for('44','8wd65QS', :service => :first_data,  :amount => 157.0) do |service|
      service.shipping 44.0
      service.tax 44.0
      service.add_shipping_as_line_item
      service.add_tax_as_line_item
    end

    assert hidden_field_set('x_line_item', 'Tax<|>Total Tax<|>Total Tax<|>1<|>44.0<|>N')
    assert hidden_field_set('x_line_item', 'Shipping<|>Shipping and Handling Cost<|>Shipping and Handling Cost<|>1<|>44.0<|>N')
  end

  def test_shipping_large
    payment_service_for('44','8wd65QS', :service => :first_data,  :amount => 157.0) do |service|
      service.ship_to_address :first_name => 'first', :last_name => 'last', :company => 'company1',
        :city => 'city2', :state => 'TX', :zip => 84601, :country => 'US'
    end
    assert hidden_field_set 'x_ship_to_city', 'city2'
    assert hidden_field_set 'x_ship_to_last_name', 'last'
    assert hidden_field_set 'x_ship_to_first_name', 'first'
    assert hidden_field_set 'x_ship_to_country', 'US'
    assert hidden_field_set 'x_ship_to_zip', '84601'
    assert hidden_field_set 'x_ship_to_company', 'company1'
    assert hidden_field_set 'x_ship_to_state', 'TX'
  end

  def test_line_item
    payment_service_for('44','8wd65QS', :service => :first_data,  :amount => 157.0) do |service|
      service.add_line_item :name => 'name1', :quantity => 1, :unit_price => 1, :tax => 'true'
      service.add_line_item :name => 'name2', :quantity => '2', :unit_price => '2'
      assert_raise(RuntimeError) do
        service.add_line_item :name => 'name3', :quantity => '3',  :unit_price => '-3'
      end
      service.tax 4
      service.shipping 5
      service.add_tax_as_line_item
      service.add_shipping_as_line_item
    end
    assert hidden_field_set 'x_line_item', 'Item 1<|>name1<|>name1<|>1<|>1.0<|>N'
  end

  def test_line_item_weird_prices
    payment_service_for('44','8wd65QS', :service => :first_data,  :amount => 157.0) do |service|
      service.add_line_item :name => 'name1', :quantity => 1, :unit_price => "1.001", :tax => 'true'
      service.add_line_item :name => 'name2', :quantity => '2', :unit_price => '1.006'
    end
    # should round the prices
    assert_no_match(/1.001/, @output_buffer)
    assert_match(/1.01/, @output_buffer)
  end

  def test_ship_to
    payment_service_for('44','8wd65QS', :service => :first_data,  :amount => 157.0) do |service|
      service.tax 4
      service.ship_to_address :first_name => 'firsty'
    end
    assert hidden_field_set 'x_ship_to_first_name', 'firsty'
  end

  def test_normal_fields
    payment_service_for('44','8wd65QS', :service => :first_data,  :amount => 157.0) do |service|
      service.setup_hash :transaction_key => '8CP6zJ7uD875J6tY',
                         :order_timestamp => 1206836763
      service.customer_id 8
      service.customer :first_name => 'Cody',
                       :last_name => 'Fauser',
                       :phone => '(555)555-5555',
                       :email => 'g@g.com'

      service.billing_address :city => 'city1',
                              :address1 => 'g',
                              :address2 => '',
                              :state => 'UT',
                              :country => 'United States of America',
                              :zip => '90210'
       service.invoice '#1000'
       service.shipping '30.00'
       service.tax '31.00'
       service.test_request 'true'
    end

    assert hidden_field_set 'x_cust_id', '8'
    assert hidden_field_set 'x_city', 'city1'
    assert hidden_field_set 'x_fp_timestamp', '1206836763'
    assert hidden_field_set 'x_last_name', 'Fauser'
    assert hidden_field_set 'x_amount', '157.0'
    assert hidden_field_set 'x_zip', '90210'
    assert hidden_field_set 'x_country', 'United States of America'
    assert hidden_field_set 'x_duplicate_window', '28800'
    assert hidden_field_set 'x_relay_response', 'TRUE'
    assert hidden_field_set 'x_first_name', 'Cody'
    assert hidden_field_set 'x_type', 'AUTH_CAPTURE'
    assert hidden_field_set 'x_version', '3.1'
    assert hidden_field_set 'x_login', '8wd65QS'
    assert hidden_field_set 'x_invoice_num', '#1000'
    assert hidden_field_set 'x_phone', '(555)555-5555'
    assert hidden_field_set 'x_fp_sequence', '44'
    assert hidden_field_set 'x_show_form', 'PAYMENT_FORM'
    assert hidden_field_set 'x_state', 'UT'
    assert hidden_field_set 'x_email', 'g@g.com'
    assert hidden_field_set 'x_fp_hash', '31d572da4e9910b36e999d73925eb01c'
    assert hidden_field_set 'x_tax', '31.00'
    assert hidden_field_set 'x_freight', '30.00'
  end

  def test_test_mode
    OffsitePayments.mode = :test
    assert_equal 'https://demo.globalgatewaye4.firstdata.com/payment', FirstData.service_url
  end

  def test_production_mode
    OffsitePayments.mode = :production
    assert_equal 'https://checkout.globalgatewaye4.firstdata.com/payment', FirstData.service_url
  ensure
    OffsitePayments.mode = :test
  end
end
