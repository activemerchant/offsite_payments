require 'test_helper'

class UniversalReturnTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @secret = 'TO78ghHCfBQ6ZBw2Q2fJ3wRwGkWkUHVs'
    @return = Universal::Return.new(query_data, :credential2 => @secret)
  end

  def test_valid_return
    assert @return.success?
  end

  def test_invalid_return
    @return = Universal::Return.new('', :credential2 => @secret)

    assert !@return.success?
  end

  def test_success_after_acknowledge
    assert @return.notification.acknowledge
    assert @return.success?
  end

  def test_return_message
    assert_equal 'helloworld', @return.message
  end

  private

  def query_data
    'x_account_id=zork&x_reference=order-500&x_currency=USD&x_test=true&x_amount=123.45&x_gateway_reference=blorb123&x_timestamp=2014-03-24T12:15:41Z&x_result=success&x_signature=55bd5acfabe65041568a94cb8981489ebced1f1eceebe0b985c8db43f3fedf91&x_message=helloworld'
  end
end
