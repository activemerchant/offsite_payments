require 'test_helper'

class MollieTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @token = 'test_8isBjQoJXJoiXRSzjhwKPO1Bo9AkVA'
    JSON.stubs(:parse).returns(CREATE_PAYMENT_RESPONSE_JSON)
  end

  def test_get_request
    @request = Mollie::API.new(@token).get_request("payments/#{@payment_id}")
    assert_equal 'tr_djsfilasX', @request['id']
    assert_equal '500.00', @request['amount']
    assert_equal 'https://example.com/return', @request['links']['redirectUrl']
  end

  def test_post_request
    @payment_id ='tr_QkwjRvZBzH'
    params =  { 
      :amount => BigDecimal.new('123.45'),
      :description => 'My order description',
      :redirectUrl => 'https://example.com/return',
      :method => 'ideal',
      :issuer => 'ideal_TESTNL99',
      :metadata => { :my_reference => 'unicorn' }
    }
    @request = Mollie::API.new(@token).post_request('payments', params)
    assert_equal 'tr_djsfilasX', @request['id']
    assert_equal '500.00', @request['amount']
    assert_equal 'https://example.com/return', @request['links']['redirectUrl']
  end

  CREATE_PAYMENT_RESPONSE_JSON = JSON.parse(<<-JSON)
    {
      "id":"tr_djsfilasX",
      "mode":"test",
      "createdDatetime":"2014-03-03T10:17:05.0Z",
      "status":"open",
      "amount":"500.00",
      "description":"My order description",
      "method":"ideal",
      "metadata":{
        "my_reference":"unicorn"
      },
      "details":null,
      "links":{
        "paymentUrl":"https://www.mollie.com/paymentscreen/mistercash/testmode/ca8195a3dc8d5cbf2f7b130654abe5a5",
        "redirectUrl":"https://example.com/return"
      }
    }
  JSON
end