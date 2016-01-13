require 'test_helper'

class MigsTest < Test::Unit::TestCase
  def setup
    @secure_hash = '76AF3392002D202A60D0AB5F9D81653C'
    @helper = OffsitePayments::Integrations::Migs::Helper.new(
                '22TEST',
                'MER123',
                credential1: 'password',
                credential2: @secure_hash,
                unique_id: 'uniq',
                cents: 2995,
                return_url: 'http://example.org/return'
              )
  end

  def test_secure_hash
    assert_equal @helper.credential_based_url,
                 'https://migs.mastercard.com.au/vpcpay'+
                 '?vpc_OrderInfo=22TEST'+
                 '&vpc_Amount=2995'+
                 '&vpc_Version=1'+
                 '&vpc_Merchant=MER123'+
                 '&vpc_AccessCode=password'+
                 '&vpc_Command=pay'+
                 '&vpc_MerchTxnRef=uniq'+
                 '&vpc_Locale=en'+
                 '&vpc_ReturnURL=http%3A%2F%2Fexample.org%2Freturn'+
                 '&vpc_SecureHash=9D8E697B247939470CE904715B15C744'
  end

  def test_just_secure_hash
    ordered_values = "#{@secure_hash}2995MER12322TEST"
    calculated = OffsitePayments::Integrations::Migs::SecureHash.calculate(
                   @secure_hash,
                   Amount: 2995,
                   MerchantId: 'MER123',
                   OrderInfo: '22TEST'
                 )
    assert_equal Digest::MD5.hexdigest(ordered_values).upcase, calculated
  end

  def test_purchase_offsite_response
    # Below response from instance running remote test
    response_string = "vpc_3DSXID=a1B8UcW%2BKYqkSinLQohGmqQd9uY%3D&vpc_3DSenrolled=U&vpc_AVSResultCode=Unsupported&vpc_AcqAVSRespCode=Unsupported&vpc_AcqCSCRespCode=Unsupported&vpc_AcqResponseCode=00&vpc_Amount=100&vpc_AuthorizeId=367739&vpc_BatchNo=20120421&vpc_CSCResultCode=Unsupported&vpc_Card=MC&vpc_Command=pay&vpc_Locale=en&vpc_MerchTxnRef=9&vpc_Merchant=TESTANZTEST3&vpc_Message=Approved&vpc_OrderInfo=1&vpc_ReceiptNo=120421367739&vpc_SecureHash=8794D9478D030B65F3092282E76283F8&vpc_TransactionNo=2000025183&vpc_TxnResponseCode=0&vpc_VerSecurityLevel=06&vpc_VerStatus=U&vpc_VerType=3DS&vpc_Version=1"
    response_params = response_string.split('&').map.with_object({}) { |obj, hash|
      key, value = obj.split('=')
      hash[key] = URI.unescape(value)
    }

    notification = OffsitePayments::Integrations::Migs::Notification.new(
                     response_params,
                     secure_hash: @secure_hash
                   )

    assert_equal '8794D9478D030B65F3092282E76283F8',
                 notification.expected_secure_hash

    assert notification.success?

    tampered_params1 = response_params.merge(
      'vpc_SecureHash' =>
      response_params['vpc_SecureHash'].gsub('83F8', '93F8')
    )
    tampered_notification1 = OffsitePayments::Integrations::Migs::Notification.new(
      tampered_params1,
      secure_hash: @secure_hash
    )
    assert_raise(SecurityError){
      tampered_notification1.acknowledge
    }

    tampered_params2 = response_params.merge(
      'vpc_Locale' =>
      response_params['vpc_Locale'].gsub('en', 'es')
    )
    tampered_notification2 = OffsitePayments::Integrations::Migs::Notification.new(
      tampered_params2,
      secure_hash: @secure_hash
    )
    assert_raise(SecurityError){ tampered_notification2.acknowledge }
  end
end
