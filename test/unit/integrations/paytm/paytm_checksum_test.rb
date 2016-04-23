require 'test_helper'

class PaytmChecksumTest < Test::Unit::TestCase
	include OffsitePayments::Integrations::Paytm

	def setup
		@merchant_key = 'lalala7897rrrrrrrr'

		@params_from_form = {"ORDER_ID"=>"order-500", "MID"=>"FreshD33860006728322", "TXN_AMOUNT"=>"500", "CALLBACK_URL"=>"http://hiiiii.ru", "CHANNEL_ID"=>"WEB", "EMAIL"=>"hi@hi.com", "MOBILE_NO"=>"7777777777", "CUST_ID"=>"1", "INDUSTRY_TYPE_ID"=>"Retail", "WEBSITE"=>"FreshDispatchweb", "REQUEST_TYPE"=>"DEFAULT"}
	end


	def test_checksum_matches
		checksumhash = Checksum.create(@params_from_form, @merchant_key)

		assert_instance_of String, checksumhash
		assert_true Checksum.verify(@params_from_form, checksumhash, @merchant_key)
	end


	def test_checksum_fails_on_wrong_params
		checksumhash = Checksum.create(@params_from_form, @merchant_key)

		assert_false Checksum.verify(@params_from_form.merge(a: 'hi'), checksumhash, @merchant_key)
	end

	def test_checksum_fails_on_wrong_checksumhash
		checksumhash = Checksum.create(@params_from_form, @merchant_key)

		assert_true  Checksum.verify(@params_from_form, checksumhash + 'higiuyuiy97', @merchant_key)
		assert_false Checksum.verify(@params_from_form, 'higiuyuiy97' + checksumhash, @merchant_key)
	end

	def test_checksum_fails_on_wrong_merchant_key
		checksumhash = Checksum.create(@params_from_form, @merchant_key)

		assert_true  Checksum.verify(@params_from_form, checksumhash, @merchant_key + 'rrr')
		assert_false Checksum.verify(@params_from_form, checksumhash, 'rrr' + @merchant_key)
	end



end
