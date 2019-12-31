require 'test_helper'

class MolpayReturnTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @secret = 'secretkey'
    key = Digest::MD5.hexdigest("12345order-10.0000molpaytest10.00MYR")
    @skey = Digest::MD5.hexdigest("2014-04-04 10:00:00molpaytest#{key}auth123#{@secret}")
    @molpay = Molpay::Return.new(query_data, :credential2 => @secret)
  end

  def test_success?
    assert @molpay.success?
  end

  def test_failed?
    Molpay::Notification.any_instance.stubs(:ssl_post).returns('DECLINED')
    molpay = Molpay::Return.new('', :credential2 => @secret)
    refute molpay.success?
  end

  def test_pending?
    molpay = Molpay::Return.new('status=22', :credential2 => @secret)
    assert molpay.pending?
  end

  private

  def query_data
    params = { 'amount'   => '10.00',
               'orderid'  => 'order-10.00',
               'appcode'  => 'auth123',
               'tranID'   => '12345',
               'domain'   => 'molpaytest',
               'status'   => '00',
               'currency' => 'MYR',
               'paydate'  => '2014-04-04 10:00:00',
               'channel'  => 'MB2u',
               'skey'     => @skey
             }
    params.collect {|k,v| "#{k}=#{CGI.escape(v.to_s)}"}.join('&')
  end
end
