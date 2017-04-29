require 'test_helper'

class PoliPayModuleTest < Test::Unit::TestCase
  include ActionViewHelperTestHelper
  include OffsitePayments::Integrations

  def setup
    super
    @options = fixtures(:poli_pay)
  end

  def transaction_options
    {
      amount:       157.0,
      currency:     'AUD',
      return_url:   "http://example.org/return",
      homepage_url: 'http://example.org',
      credential2:   @options[:password]
    }
  end

  def test_bad_password
    options = transaction_options
    options[:credential2] = 'wrong'
    helper = PoliPay::Helper.new('22TEST', @options[:login], options)
    response = helper.credential_based_url

    assert_equal PoliPay::RequestError, response.class
    assert !response.success?
    assert_equal 'Authorization has been denied for this request.',
                 response.message
  end

  def test_required_fields
    options = transaction_options.except(:homepage_url)
    helper = PoliPay::Helper.new('22TEST', @options[:login], options)
    assert_raise KeyError.new('key not found: :homepage_url') do
      helper.credential_based_url
    end
  end

  def test_url_generation
    interface = PoliPay::Interface.new(@options[:login], @options[:password])
    response = interface.credential_based_url(
      MerchantReference: '22TEST',
      Amount: 1.0,
      CurrencyCode: 'AUD'
    )

    assert_equal PoliPay::RequestError, response.class
    assert !response.success?
    assert_equal 14062, response.error_code
    assert_equal 'One or more fields that are mandatory did not have values ' +
                 'specified',
                 response.error_code_text
    assert_equal "Failed to initiate transaction for merchant 'S6101959' " +
                 "with reference '22TEST': The Success URL was not specified",
                 response.error_message
  end

  def test_generates_url
    options = transaction_options
    helper = PoliPay::Helper.new('22TEST', @options[:login], options)
    url = helper.credential_based_url

    expected_base_url = "https://txn.apac.paywithpoli.com/?Token="
    assert_equal expected_base_url, url[0..expected_base_url.length-1]
  end

  def test_token_url
    token = '6MIP8TMf1zwNfTnO2nx1+uq5Xd/6S7FN' # + to test escaping
    assert_equal "#{PoliPay.base_url}/Transaction/GetTransaction?token="+
                 '6MIP8TMf1zwNfTnO2nx1%2Buq5Xd%2F6S7FN',
                 PoliPay.query_url(token)
  end

  def test_incomplete_query
    params = { 'token' => '6MIP8TMf1zwNfTnO2nx1+uq5Xd/6S7FN' }
    notification = PoliPay::Notification.new(params, @options)

    assert notification.acknowledge
    assert !notification.complete?
    assert !notification.success?
    assert_equal '996119475634', notification.transaction_id
    assert_equal 0.0, notification.gross
    assert_equal 'AUD', notification.currency
  end

  def test_complete_query
    params = { 'token' => 'pievIHFi0eOLiQ2GMyE1PllZYqs8yvCt' }
    notification = PoliPay::Notification.new(params, @options)

    assert notification.acknowledge
    assert notification.complete?
    assert notification.success?
    assert_equal '996119476227', notification.transaction_id
    assert_equal 157.0, notification.gross
    assert_equal 'AUD', notification.currency
  end

  def test_financial_institutions
    interface = PoliPay::Interface.new(@options[:login], @options[:password])
    financial_institutions = interface.financial_institutions

    assert_equal Array, financial_institutions.class
    assert_equal 1, financial_institutions.size

    ibank = financial_institutions.first
    assert_equal PoliPay::FinancialInstitution, ibank.class
    assert_equal 'iBank AU 01', ibank.name
    assert_equal 'iBankAU01', ibank.code
    assert ibank.online?
  end
end
