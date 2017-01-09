require 'test_helper'

class PaytmReturnTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @secret = 'kbzk1DSbJiV_O3p5'
    @return = Paytm::Return.new(query_data, :credential2 => @secret)
  end

  def test_valid_return
    assert @return.success?
  end

  def test_invalid_return
    @return = Paytm::Return.new('', :credential2 => @secret)

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
    'x_account_id=zork&x_reference=order-500&x_currency=USD&x_test=true&x_amount=123.45&x_gateway_reference=blorb123&x_timestamp=2014-03-24T12:15:41Z&x_result=success&x_signature=jJW%2bnwXufWm6lw4tZ6joRI5BIBx/K4eTEaLxHgWgF/w=&x_message=helloworld'
  end
end
