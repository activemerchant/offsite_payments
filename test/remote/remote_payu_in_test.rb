require 'test_helper'

class RemotePayuInTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    params = {'mihpayid' => '403993715508030204', 'mode' => 'CC', 'status' => 'success', 'unmappedstatus' => 'captured', 'key' => 'merchant_id', 'txnid' => '4ba4afe87f7e73468f2a', 'amount' => '10.00', 'discount' => '0.00', 'addedon' => '2013-05-10 18 32 30', 'productinfo' => 'Product Info', 'firstname' => 'Payu-Admin', 'lastname' => '', 'address1' => '', 'address2' => '', 'city' => '', 'state' => '', 'country' => '', 'zipcode' => '', 'email' => 'test@example.com', 'phone' => '1234567890', 'udf1' => '', 'udf2' =>'', 'udf3' => '','udf4' => '','udf5' => '','udf6' => '','udf7' => '','udf8' => '','udf9' => '','udf10' => '','hash' =>'d6a5544072d036dc422d1c6393a8da75233d5e30ffc848f11682f121d67cd80c0d4fed1067b99918b5a377b7dcf1c8c9c79975abdf9f444692b35bf34d494105', 'field1' => '313069903923', 'field2' => '999999', 'field3' => '59117331831301', 'field4' => '-1', 'field5' => '','field6' => '','field7' => '','field8' => '','PG_TYPE' => 'HDFC','bank_ref_num' =>'59117331831301','bankcode'=>'CC','error'=>'E000','cardnum'=>'512345XXXXXX2346','cardhash' => '766f0227cc4b4c5f773a04cb31d8d1c5be071dd8d08fe365ecf5e2e5c947546d'}
    @payu_in = PayuIn::Notification.new(http_raw_data, :merchant_id => 'merchant_id', :secret_key => 'secret', :params => params)
  end

  def test_raw
    OffsitePayments.mode = :production
    assert_equal "https://secure.payu.in/_payment.php", PayuIn.service_url

    OffsitePayments.mode = :test
    assert_equal "https://test.payu.in/_payment.php", PayuIn.service_url

    assert_nothing_raised do
      assert @payu_in.checksum_ok?
    end
  end

  private
  def http_raw_data
   "mihpayid=403993715508030204&mode=CC&status=success&unmappedstatus=captured&key=merchant_id&txnid=4ba4afe87f7e73468f2a&amount=10.00&discount=0.00&addedon=2013-05-10 18 32 30&productinfo=Product Info&firstname=Payu-Admin&lastname=&address1=&address2=&city=&state=&country=&zipcode=&email=test@example.com&phone=1234567890&udf1=&udf2=&udf3=&udf4=&udf5=&udf6=&udf7=&udf8=&udf9=&udf10=&hash=d6a5544072d036dc422d1c6393a8da75233d5e30ffc848f11682f121d67cd80c0d4fed1067b99918b5a377b7dcf1c8c9c79975abdf9f444692b35bf34d494105&field1=313069903923&field2=999999&field3=59117331831301&field4=-1&field5=&field6=&field7=&field8=&PG_TYPE=HDFC&bank_ref_num=59117331831301&bankcode=CC&error=E000&cardnum=512345XXXXXX2346&cardhash=766f0227cc4b4c5f773a04cb31d8d1c5be071dd8d08fe365ecf5e2e5c947546d"
  end
end
