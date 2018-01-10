require 'test_helper'

class MollieTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @api = Mollie::API.new('test_8isBjQoJXJoiXRSzjhwKPO1Bo9AkVA')
    @api_response = {
      "id" => "tr_djsfilasX",
      "mode" => "test",
      "createdDatetime" => "2014-03-03T10:17:05.0Z",
      "status" => "open",
      "amount" => "500.00",
      "description" => "My order description",
      "method" => "ideal",
      "metadata" => {
        "my_reference" => "unicorn"
      },
      "details" => nil,
      "links" => {
        "paymentUrl" => "https://www.mollie.com/paymentscreen/mistercash/testmode/ca8195a3dc8d5cbf2f7b130654abe5a5",
        "redirectUrl" => "https://example.com/return"
      }
    }.to_json
  end

  def test_get_request
    @api
      .expects(:ssl_request)
      .with(
        :get,
        'https://api.mollie.nl/v1/payments/tr_QkwjRvZBzH',
        nil,
        {
          "Authorization" => "Bearer test_8isBjQoJXJoiXRSzjhwKPO1Bo9AkVA",
          "Content-Type" => "application/json"
        }
      )
      .returns(@api_response)

    response = @api.get_request("payments/tr_QkwjRvZBzH")

    assert_equal 'tr_djsfilasX', response['id']
    assert_equal '500.00', response['amount']
    assert_equal 'https://example.com/return', response['links']['redirectUrl']
  end

  def test_post_request
    params =  {
      :amount => BigDecimal.new('123.45'),
      :description => 'My order description',
      :redirectUrl => 'https://example.com/return',
      :method => 'ideal',
      :issuer => 'ideal_TESTNL99',
      :metadata => { :my_reference => 'unicorn' }
    }

    @api
      .expects(:ssl_request)
      .with(
        :post,
        'https://api.mollie.nl/v1/payments',
        params.to_json,
        {
          "Authorization" => "Bearer test_8isBjQoJXJoiXRSzjhwKPO1Bo9AkVA",
          "Content-Type" => "application/json"
        }
      )
      .returns(@api_response)


    response = @api.post_request('payments', params)
    assert_equal 'tr_djsfilasX', response['id']
    assert_equal '500.00', response['amount']
    assert_equal 'https://example.com/return', response['links']['redirectUrl']
  end
end
