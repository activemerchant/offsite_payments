require 'test_helper'

class ReturnTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_return
    r = Return.new('')
    assert r.success?
  end

  def test_parse
    r = Return.new('')
    assert r.parse('account=test').is_a?(Hash)
  end

  def test_parse_with_bad_query
    r = Return.new('')
    assert r.parse('&account=test').is_a?(Hash)
    assert r.parse('key1=value1&key2&key3=value3').is_a?(Hash)
    assert r.parse('foooo=value1&=value&key3=value3').is_a?(Hash)
    assert r.parse('key1=value1&&key3=value3').is_a?(Hash)
  end
end
