require 'test_helper'

class ValitorHelperTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @helper = Valitor::Helper.new(
      'order-500',
      'cody@example.com',
      :currency => 'USD',
      :credential2 => '123',
      :amount => 1000
      )
  end

  def test_basic_helper_fields
    assert_field 'MerchantID', 'cody@example.com'

    assert_field 'AuthorizationOnly', '0'
    assert_field 'ReferenceNumber', 'order-500'
    assert_field 'Currency', 'USD'

    assert_equal Digest::MD5.hexdigest(['123', '0', '1', '1000,00', '0', 'cody@example.com', 'order-500', 'USD'].join('')),
                 @helper.form_fields['DigitalSignature']
  end

  def test_products
    @helper.product(1, :description => 'one', :quantity => '2', :amount => 100, :discount => 50)
    @helper.product(2, :description => 'two', :amount => 200)

    assert_field 'Product_1_Description', 'one'
    assert_field 'Product_1_Quantity', '2'
    assert_field 'Product_1_Price', '100'
    assert_field 'Product_1_Discount', '50'

    assert_field 'Product_2_Description', 'two'
    assert_field 'Product_2_Quantity', '1'
    assert_field 'Product_2_Price', '200'
    assert_field 'Product_2_Discount', '0'

    assert_equal Digest::MD5.hexdigest(
      ['123', '0',
        '2', '100,00', '50',
        '1', '200,00', '0',
        'cody@example.com', 'order-500', 'USD'].join('')),
      @helper.form_fields['DigitalSignature']
  end

  def test_invalid_products
    assert_nothing_raised do
      @helper.product(1, :description => '1', :amount => 100)
    end

    assert_nothing_raised ArgumentError do
      @helper.product('2', :description => '2', :amount => 100)
    end

    assert_raise ArgumentError do
      @helper.product(501, :description => '501', :amount => 100)
    end

    assert_raise ArgumentError do
      @helper.product(0, :description => '0', :amount => 100)
    end

    assert_raise ArgumentError do
      @helper.product(3, :amount => 100)
    end

    assert_raise ArgumentError do
      @helper.product(3, :description => 100)
    end

    assert_raise ArgumentError do
      @helper.product(3, :amount => 100, :bogus => 'something')
    end
  end

  def test_authorize_only
    @helper.authorize_only
    assert_field 'AuthorizationOnly', '1'
  end

  def test_missing_password
    @helper.instance_eval{@security_number = nil}
    assert_raise ArgumentError do
      @helper.form_fields
    end
  end

  def test_urls
    @helper.return_url = 'http://example.com/return'
    assert_field 'PaymentSuccessfulURL', 'http://example.com/return'

    @helper.cancel_return_url = 'http://example.com/cancel'
    assert_field 'PaymentCancelledURL', 'http://example.com/cancel'

    @helper.notify_url = 'http://example.com/notify'
    assert_field 'PaymentSuccessfulServerSideURL', 'http://example.com/notify'

    digest = ['123', '0',
         '1', '1000,00', '0',
        'cody@example.com', 'order-500', 'http://example.com/return', 'http://example.com/notify', 'USD'].join('')

    assert_equal Digest::MD5.hexdigest(digest), @helper.form_fields['DigitalSignature']
  end

  def test_collect_customer_info
    assert_field 'DisplayBuyerInfo', '0'
    @helper.collect_customer_info
    assert_field 'DisplayBuyerInfo', '1'
  end

  def test_require_and_hide_fields
    %w(SSN Name Address City Country Phone Email Comments).each do |name|
      assert_field "Require#{name}", nil
      @helper.send("require_#{name.downcase}".to_sym)
      assert_field "Require#{name}", '1'

      assert_field "Hide#{name}", nil
      @helper.send("hide_#{name.downcase}".to_sym)
      assert_field "Hide#{name}", '1'
    end

    assert_field "RequirePostalCode", nil
    @helper.require_postal_code
    assert_field "RequirePostalCode", '1'

    assert_field "HidePostalCode", nil
    @helper.hide_postal_code
    assert_field "HidePostalCode", '1'
  end


  def test_timeout_and_redirect
    assert_field "PaymentSuccessfulAutomaticRedirect", nil
    @helper.payment_successful_automatic_redirect
    assert_field "PaymentSuccessfulAutomaticRedirect", '1'

    assert_field "SessionExpiredRedirectURL", nil
    @helper.session_expired_redirect_url = "http://example.com"
    assert_field "SessionExpiredRedirectURL", 'http://example.com'

    assert_field "SessionExpiredTimeoutInSeconds", nil
    @helper.session_expired_timeout_in_seconds = "10"
    assert_field "SessionExpiredTimeoutInSeconds", '10'
  end

  def test_card_loan_mappings
    assert_field "IsCardLoan", nil
    @helper.is_card_loan
    assert_field "IsCardLoan", '1'

    assert_field "IsInterestFree", nil
    @helper.card_loan_is_interest_free
    assert_field "IsInterestFree", '1'

    assert_field "MerchantName", nil
    @helper.card_loan_user_name = "ExampleCardLoanName"
    assert_field "MerchantName", 'ExampleCardLoanName'
  end

  def test_misc_mappings
    assert_field 'PaymentSuccessfulURLText', nil
    @helper.success_text = 'text'
    assert_field 'PaymentSuccessfulURLText', 'text'

    assert_field 'Language', 'IS'
    @helper.language = 'EN'
    assert_field 'Language', 'EN'
  end

  def test_amount_gets_sent_without_decimals_for_non_decimal_currencies
    @helper = Valitor::Helper.new('order-500', 'cody@example.com', :currency => 'ISK', :credential2 => '123', :amount => 115.10)
    @helper.form_fields
    assert_field "Product_1_Price", 115
  end

  def test_amount_gets_sent_with_decimals_for_decimal_currencies
    @helper = Valitor::Helper.new('order-500', 'cody@example.com', :currency => 'USD', :credential2 => '123', :amount => 115.10)
    @helper.form_fields
    assert_field "Product_1_Price", '115,10'
  end
end
