require 'test_helper'
require 'net/http'

class RemoteMigsTest < Test::Unit::TestCase
  def setup
    @gateway = fixtures(:migs_purchase)
    @capture_gateway = fixtures(:migs_capture)

    @amount = 100
    @declined_amount = 105
  end

  def test_server_purchase_url
    options = {
      order_id:   1,
      unique_id:  9,
      return_url: 'http://localhost:8080/payments/return',
      credential1: @gateway[:password],
      credential2: @gateway[:secure_hash],
      cents: @amount
    }

    helper = OffsitePayments::Integrations::Migs::Helper.new(
      1, @gateway[:login], options)
    choice_url = helper.credential_based_url
    assert_response_contains 'Pay securely by clicking on the card logo below', choice_url

    responses = {
      'visa'             => 'You have chosen <B>VISA</B>',
      'master'           => 'You have chosen <B>MasterCard</B>',
      'diners_club'      => 'You have chosen <B>Diners Club</B>',
      'american_express' => 'You have chosen <B>American Express</B>'
    }

    responses.each_pair do |card_type, response_text|
      helper = OffsitePayments::Integrations::Migs::Helper.new(
                 1,
                 @gateway[:login],
                 options.merge(
                   credential1: @gateway[:password],
                   credential2: @gateway[:secure_hash],
                   card_type: card_type
                 )
               )
      url = helper.credential_based_url
      assert_response_contains response_text, url
    end
  end

  private

  include ActiveUtils::PostsData
  def assert_response_contains(text, url)
    response = https_response(url)
    assert response.body.include?(text), "#{text} not found in body: #{response}"
  end

  def https_response(url, cookie = nil)
    headers = cookie ? {'Cookie' => cookie} : {}
    response = raw_ssl_request(:get, url, nil, headers)
    if response.is_a?(Net::HTTPRedirection)
      new_cookie = [cookie, response['Set-Cookie']].compact.join(';')
      response = https_response(response['Location'], new_cookie)
    end
    response
  end
end
