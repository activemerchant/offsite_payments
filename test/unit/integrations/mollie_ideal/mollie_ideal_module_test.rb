require 'test_helper'

class MollieIdealModuleTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_notification_method
    assert_instance_of MollieIdeal::Notification, MollieIdeal.notification("id=482d599bbcc7795727650330ad65fe9b", :credential1 => '1234567')
  end

  def test_return_method
    assert_instance_of MollieIdeal::Return, MollieIdeal.return("", :credential1 => '1234567')
  end

  def test_live?
    OffsitePayments.stubs(:mode).returns(:development)
    assert !MollieIdeal.live?

    OffsitePayments.stubs(:mode).returns(:production)
    assert MollieIdeal.live?
  end

  def test_required_redirect_parameter
    OffsitePayments.stubs(:mode).returns(:development)

    assert MollieIdeal.requires_redirect_param?
    assert MollieIdeal.redirect_param_options(:credential1 => "test_blah").include?(["Rabobank", "ideal_RABONL2U"])

    live_issuers = MollieIdeal.redirect_param_options(:credential1 => "live_blah")
    assert !live_issuers.include?(["TBM Bank", "ideal_TESTNL99"])
    assert live_issuers.include?(["Rabobank", "ideal_RABONL2U"])
  end

  def test_retrieve_issuers
    Mollie::API.stubs(:new).with('1234567').returns(@mock_api = mock())

    @mock_api.expects(:get_request).returns(ISSERS_RESPONSE_JSON)
    issuers = MollieIdeal.retrieve_issuers('1234567')
    assert_equal [["TBM Bank", "ideal_TESTNL99"]], issuers
  end

  ISSERS_RESPONSE_JSON = JSON.parse(<<-JSON)
    {
      "totalCount":1,
      "offset":0,
      "count":1,
      "data":[
        {
          "id":"ideal_TESTNL99",
          "name":"TBM Bank",
          "method":"ideal"
        }
      ]
    }
  JSON
end
