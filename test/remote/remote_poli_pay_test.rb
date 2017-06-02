require 'test_helper'

class RemotePoliPayTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    super
    @options  = fixtures(:poli_pay)
    @login    = @options[:login]
    @password = @options[:password]
  end

  def transaction_options
    {
      amount:       157.0,
      currency:     'AUD',
      return_url:   "http://example.org/return",
      homepage_url: 'http://example.org',
      password:     @password
    }
  end

  def test_bad_password
    options = transaction_options
    options[:password] = 'wrong'
    helper = PoliPay::Helper.new('22TEST', @login, options)
    error = nil
    begin
      response = helper.credential_based_url
    rescue PoliPay::UrlInterface::UrlRequestError => e
      error = e
    end

    assert !error.nil?
    assert !error.success?
    assert_equal 'Authorization has been denied for this request.',
                 error.message
  end

  def test_required_fields
    options = transaction_options.except(:homepage_url)
    helper = PoliPay::Helper.new('22TEST', @login, options)
    assert_raise KeyError.new('key not found: :homepage_url') do
      helper.credential_based_url
    end
  end

  def test_url_generation
    interface = PoliPay::UrlInterface.new(@login, @password)
    error = nil
    begin
      interface.call(
        MerchantReference: '22TEST',
        Amount: 1.0,
        CurrencyCode: 'AUD'
      )
    rescue PoliPay::UrlInterface::UrlRequestError => e
      error = e
    end

    assert !error.nil?
    assert !error.success?
    assert_equal 14062, error.error_code
    assert_equal 'One or more fields that are mandatory did not have values ' +
                 'specified',
                 error.error_code_text
    assert_equal "Failed to initiate transaction for merchant '#{@login}' " +
                 "with reference '22TEST': The Success URL was not specified",
                 error.error_message
  end

  def test_generates_url
    options = transaction_options
    helper = PoliPay::Helper.new('22TEST', @login, options)
    url = helper.credential_based_url
    expected_base_url = "https://txn.apac.paywithpoli.com/?Token="
    assert_equal expected_base_url, url[0..expected_base_url.length-1]
  end

  def test_incomplete_query
    params = { 'token' => 'l7rySY8HEAo9MOsPsVQXtHCPJWmcxmDv' }
    notification = PoliPay::Notification.new(params, @options)

    assert notification.acknowledge
    assert !notification.complete?
    assert !notification.success?
    assert_equal '996123326514', notification.transaction_id
    assert_equal 0.0, notification.gross
    assert_equal 'AUD', notification.currency
  end

  def test_complete_query
    params = { 'token' => 'YKiwCr9ttTCpEw6JL3EomJaVu/JfXzT5' }
    notification = PoliPay::Notification.new(params, @options)

    assert notification.acknowledge
    assert notification.complete?
    assert notification.success?
    assert_equal '996123326635', notification.transaction_id
    assert_equal 157.0, notification.gross
    assert_equal 'AUD', notification.currency
  end

  def test_financial_institutions
    interface = PoliPay::FinancialInstitutionsInterface.new(@login, @password)
    financial_institutions = interface.call

    assert_equal Array, financial_institutions.class
    assert_equal 1, financial_institutions.size

    ibank = financial_institutions.first
    assert_equal PoliPay::FinancialInstitution, ibank.class
    assert_equal 'iBank AU 01', ibank.name
    assert_equal 'iBankAU01', ibank.code
    assert ibank.online?
  end
end
