require 'test_helper'

class <%= class_name %>Test < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_notification_method
    assert_instance_of <%= class_name %>::Notification, <%= class_name %>.notification('name=cody')
  end
end

class <%= class_name %>HelperTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @helper = <%= class_name %>::Helper.new('order-500','cody@example.com', :amount => 500, :currency => 'USD')
  end

  def test_basic_helper_fields
    assert_field '', 'cody@example.com'

    assert_field '', '5.00'
    assert_field '', 'order-500'
  end

  def test_customer_fields
    @helper.customer :first_name => 'Cody', :last_name => 'Fauser', :email => 'cody@example.com'
    assert_field '', 'Cody'
    assert_field '', 'Fauser'
    assert_field '', 'cody@example.com'
  end

  def test_address_mapping
    @helper.billing_address :address1 => '1 My Street',
                            :address2 => '',
                            :city => 'Leeds',
                            :state => 'Yorkshire',
                            :zip => 'LS2 7EE',
                            :country  => 'CA'

    assert_field '', '1 My Street'
    assert_field '', 'Leeds'
    assert_field '', 'Yorkshire'
    assert_field '', 'LS2 7EE'
  end

  def test_unknown_address_mapping
    @helper.billing_address :farm => 'CA'
    assert_equal 3, @helper.fields.size
  end

  def test_unknown_mapping
    assert_nothing_raised do
      @helper.company_address :address => '500 Dwemthy Fox Road'
    end
  end

  def test_setting_invalid_address_field
    fields = @helper.fields.dup
    @helper.billing_address :street => 'My Street'
    assert_equal fields, @helper.fields
  end
end

class <%= class_name %>NotificationTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @<%= identifier %> = <%= class_name %>::Notification.new(http_raw_data)
  end

  def test_accessors
    assert @<%= identifier %>.complete?
    assert_equal "", @<%= identifier %>.status
    assert_equal "", @<%= identifier %>.transaction_id
    assert_equal "", @<%= identifier %>.item_id
    assert_equal "", @<%= identifier %>.gross
    assert_equal "", @<%= identifier %>.currency
    assert_equal "", @<%= identifier %>.received_at
    assert @<%= identifier %>.test?
  end

  def test_compositions
    assert_equal Money.new(3166, 'USD'), @<%= identifier %>.amount
  end

  # Replace with real successful acknowledgement code
  def test_acknowledgement

  end

  def test_send_acknowledgement
  end

  def test_respond_to_acknowledge
    assert @<%= identifier %>.respond_to?(:acknowledge)
  end

  private
  def http_raw_data
    ""
  end
end
