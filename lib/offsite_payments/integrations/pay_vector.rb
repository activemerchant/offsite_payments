#!/bin/env ruby
# encoding: utf-8

module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module PayVector

      mattr_accessor :service_url
      self.service_url = 'https://mms.iridiumcorp.net/Pages/PublicPages/PaymentForm.aspx'

      def self.notification(post, options = {})
        Notification.new(post, options)
      end

      class Helper < OffsitePayments::Helper
        
        # Replace with the real mapping
        mapping :account, "MerchantID"
        mapping :order, 'OrderID'
        mapping :currency, 'CurrencyCode'
        mapping :transaction_type, 'TransactionType'
        
        mapping :customer, :email => 'EmailAddress',
                           :phone => 'PhoneNumber'

        mapping :billing_address, :city     => 'City',
                                  :address1 => 'Address1',
                                  :address2 => 'Address2',
                                  :state    => 'State',
                                  :zip      => 'PostCode',
                                  :country  => 'CountryCode'

        mapping :notify_url, 'ServerResultURL'
        mapping :return_url, 'CallbackURL'
        mapping :description, 'OrderDescription'
        
         # Fetches the md5secret and adds MERCHANT_ID and API TYPE to the form
        def initialize(order, account, options = {})
          #store merchant password and the preSharedKey as private variables so they aren't added to the form
          @merchant_password = options.delete(:credential2)
          @pre_shared_key = options.delete(:credential3)
          #currency is given as 3 char code - so convert it to ISO code
          options[:currency] = convert_currency_short_to_ISO_code(options[:currency])
          order = order.to_s
          options.each do |key, option|
            options[key] = option.to_s
          end
          super

          add_field("OrderDescription", "ActiveMerchant Order " + order)
          if(options.has_key?(:amount))
            add_field("Amount", minor_currency_from_major(options[:amount], options[:currency]))
          end

          transaction_date_time
          populate_fields_with_defaults
        end
        
        def minor_currency_from_major(amount, currency_iso_code)
          exponent = OffsitePayments::Integrations::PayVector::ISOCurrencies::get_exponent_from_ISO_code(currency_iso_code)
          amount = amount.to_f
          amount *= 10**exponent
          return amount.to_i.to_s
        end

        #PayVector requires country ISO code, so convert the given 2 char code
        def billing_address(params={})
          super
          add_field('CountryCode', OffsitePayments::Integrations::PayVector::ISOCountries::get_ISO_code_from_2_digit_short(@fields['CountryCode']))
        end
        
        #Concat first and last names
        def customer(params={})
          add_field(mappings[:customer][:email], params[:email])
          add_field(mappings[:customer][:phone], params[:phone])
          add_field('CustomerName', "#{params[:first_name]} #{params[:last_name]}")
        end
        
        def convert_currency_short_to_ISO_code(currencyCode)
          if(currencyCode.nil?)
            currencyCode = "GBP"
          end
          return OffsitePayments::Integrations::PayVector::ISOCurrencies::get_ISO_code_from_short(currencyCode)
        end
        
        def form_fields
          @fields = @fields.merge( {"HashDigest" => generate_hash_digest} )
        end
        
        def generate_hash_digest          
          stringToHash = "PreSharedKey=#{@pre_shared_key}" +
          "&MerchantID=" + @fields["MerchantID"] +
          "&Password=#{@merchant_password}" +
          "&Amount=" + @fields["Amount"] +
          "&CurrencyCode=" + @fields["CurrencyCode"] +
          "&EchoAVSCheckResult=true" +
          "&EchoCV2CheckResult=true" +
          "&EchoThreeDSecureAuthenticationCheckResult=true" +
          "&EchoCardType=true" +
          "&OrderID=" + @fields["OrderID"] +
          "&TransactionType=" + @fields["TransactionType"] +
          "&TransactionDateTime=" + @fields["TransactionDateTime"] +
          "&CallbackURL=" + @fields["CallbackURL"] +
          "&OrderDescription=" + @fields["OrderDescription"] +
          "&CustomerName=" + @fields["CustomerName"] +
          "&Address1=" + @fields["Address1"] +
          "&Address2=" + @fields["Address2"] +
          "&Address3=" +
          "&Address4=" +
          "&City=" + @fields["City"] +
          "&State=" + @fields["State"] +
          "&PostCode=" + @fields["PostCode"] +
          "&CountryCode=" + @fields["CountryCode"] +
          "&EmailAddress=" + @fields["EmailAddress"] +
          "&PhoneNumber=" + @fields["PhoneNumber"] +
          "&EmailAddressEditable=true" +
          "&PhoneNumberEditable=true" +
          "&CV2Mandatory=true" +
          "&Address1Mandatory=true" +
          "&CityMandatory=true" +
          "&PostCodeMandatory=true" +
          "&StateMandatory=true" +
          "&CountryMandatory=true" +
          "&ResultDeliveryMethod=" + @fields["ResultDeliveryMethod"] +
          "&ServerResultURL=" + @fields["ServerResultURL"] +
          "&PaymentFormDisplaysResult=" +
          "&ServerResultURLCookieVariables=" +
          "&ServerResultURLFormVariables=" +
          "&ServerResultURLQueryStringVariables="

          return Digest::SHA1.hexdigest stringToHash
        end

        def transaction_date_time
          add_field('TransactionDateTime', Time.now.strftime("%Y-%m-%d %H:%M:%S %:z"))
        end
        
        private
        
        def populate_fields_with_defaults
          default_blank_fields = ["MerchantID", "Amount", "CurrencyCode", "OrderID",
            "TransactionDateTime", "CallbackURL", "OrderDescription", "CustomerName", "Address1", "Address2", "Address3", "Address4", "City",
            "State", "PostCode", "CountryCode", "EmailAddress", "PhoneNumber", "ServerResultURL",
            "PaymentFormDisplaysResult", "ServerResultURLCookieVariables", "ServerResultURLFormVariables", "ServerResultURLQueryStringVariables"]

          default_blank_fields.each do |field|
            if(!@fields.has_key?(field))
              @fields[field] = ""
            end
          end
          
          default_true_fields = ["EchoAVSCheckResult", "EchoCV2CheckResult", "EchoThreeDSecureAuthenticationCheckResult", "EchoCardType", "CV2Mandatory", "Address1Mandatory",
            "CityMandatory", "PostCodeMandatory", "StateMandatory", "CountryMandatory", "EmailAddressEditable", "PhoneNumberEditable", ]
            
          default_true_fields.each do |field|
            if(!@fields.has_key?(field))
              @fields[field] = "true"
            end
          end
          
          if(!@fields.has_key?("ResultDeliveryMethod"))
            @fields["ResultDeliveryMethod"] = "POST"
          end
          if(!@fields.has_key?("TransactionType"))
            @fields["TransactionType"] = "SALE"
          end
          
        end
      end

      class Notification < OffsitePayments::Notification
        def complete?
          status == "Completed"
        end

        def item_id
          params['OrderID']
        end

        def transaction_id
          params['CrossReference']
        end
        
        def message
          params['Message']
        end
        
        def card_type
          params['CardType']
        end

        # When was this payment received by the client.
        def received_at
          params['TransactionDateTime']
        end

        def payer_email
          params['EmailAddress']
        end

        def security_key
          params['HashDigest']
        end

        # the money amount we received in X.2 decimal.
        def gross
          exponent = OffsitePayments::Integrations::PayVector::ISOCurrencies::get_exponent_from_ISO_code(@params["CurrencyCode"])
          gross = @params['Amount'].to_f
          gross /= 10**exponent
          gross = sprintf('%.0' + exponent.to_i.to_s + 'f', gross)
        end
        
        def currency
          OffsitePayments::Integrations::PayVector::ISOCurrencies::get_short_from_ISO_code(@params["CurrencyCode"])
        end

        # No way to tell if using a test transaction as the only difference is in authentication credentials
        def test?
          params[''] == 'test'
        end

        def status
          if(params['StatusCode'] == "0")
            return "Completed"
          elsif(params['StatusCode'] == "20" && params['PreviousStatusCode'] == "0")
            return "Duplicate transaction"
          else
            return "Failed"
          end
        end

        # Acknowledge the transaction to PayVector. This method has to be called after a new
        # apc arrives. PayVector will verify that all the information we received is correct and will return an
        # ok or a fail.
        def acknowledge(authcode = nil)
          if(security_key.blank? || @options[:credential2].blank? || @options[:credential3].blank?)
            return false
          end

          return generate_hash_digest == security_key
        end

        private

        # Take the posted data and move the relevant data into a hash
        def parse(post)
          @raw = post.to_s
          for line in @raw.split('&')
            key, value = *line.scan( %r{^([A-Za-z0-9_.-]+)\=(.*)$} ).flatten
            params[key] = CGI.unescape(value.to_s) if key.present?
          end
        end
        
        def generate_hash_digest
          stringToHash = 
          "PreSharedKey=" + @options[:credential3] +
          "&MerchantID=" + @params["MerchantID"] +
          "&Password=" + @options[:credential2] +
          "&StatusCode=" + @params["StatusCode"] +
          "&Message=" + @params["Message"] +
          "&PreviousStatusCode=" + @params["PreviousStatusCode"] +
          "&PreviousMessage=" + @params["PreviousMessage"] +
          "&CrossReference=" + @params["CrossReference"] +
          "&AddressNumericCheckResult=" + @params["AddressNumericCheckResult"] +
          "&PostCodeCheckResult=" + @params["PostCodeCheckResult"] +
          "&CV2CheckResult=" + @params["CV2CheckResult"] +
          "&ThreeDSecureAuthenticationCheckResult=" + @params["ThreeDSecureAuthenticationCheckResult"] +
          "&CardType=" + @params["CardType"] +
          "&CardClass=" + @params["CardClass"] +
          "&CardIssuer=" + @params["CardIssuer"] +
          "&CardIssuerCountryCode=" + @params["CardIssuerCountryCode"] +
          "&Amount=" + @params["Amount"] +
          "&CurrencyCode=" + @params["CurrencyCode"] +
          "&OrderID=" + @params["OrderID"] +
          "&TransactionType=" + @params["TransactionType"] +
          "&TransactionDateTime=" + @params["TransactionDateTime"] +
          "&OrderDescription=" + @params["OrderDescription"] +
          "&CustomerName=" + @params["CustomerName"] +
          "&Address1=" + @params["Address1"] +
          "&Address2=" + @params["Address2"] +
          "&Address3=" + @params["Address3"] +
          "&Address4=" + @params["Address4"] +
          "&City=" + @params["City"] +
          "&State=" + @params["State"] +
          "&PostCode=" + @params["PostCode"] +
          "&CountryCode=" + @params["CountryCode"] +
          "&EmailAddress=" + @params["EmailAddress"] +
          "&PhoneNumber=" + @params["PhoneNumber"]
          
          return Digest::SHA1.hexdigest stringToHash
        end
      end

      class ISOCurrencies

        @@currencies = Array.new
        @@currencies << {:iso_code => 634, :currency => "Qatari Rial", :currency_short => "QAR", :exponent => 2}
        @@currencies << {:iso_code => 566, :currency => "Naira", :currency_short => "NGN", :exponent => 2}
        @@currencies << {:iso_code => 678, :currency => "Dobra", :currency_short => "STD", :exponent => 2}
        @@currencies << {:iso_code => 943, :currency => "Metical", :currency_short => "MZN", :exponent => 2}
        @@currencies << {:iso_code => 826, :currency => "Pound Sterling", :currency_short => "GBP", :exponent => 2}
        @@currencies << {:iso_code => 654, :currency => "Saint Helena Pound", :currency_short => "SHP", :exponent => 2}
        @@currencies << {:iso_code => 704, :currency => "Vietnamese ??ng", :currency_short => "VND", :exponent => 2}
        @@currencies << {:iso_code => 952, :currency => "CFA Franc BCEAO", :currency_short => "XOF", :exponent => 0}
        @@currencies << {:iso_code => 356, :currency => "Indian Rupee", :currency_short => "INR", :exponent => 2}
        @@currencies << {:iso_code => 807, :currency => "Denar", :currency_short => "MKD", :exponent => 2}
        @@currencies << {:iso_code => 959, :currency => "Gold (one Troy ounce)", :currency_short => "XAU", :exponent => 0}
        @@currencies << {:iso_code => 410, :currency => "South Korean Won", :currency_short => "KRW", :exponent => 0}
        @@currencies << {:iso_code => 946, :currency => "Romanian New Leu", :currency_short => "RON", :exponent => 2}
        @@currencies << {:iso_code => 949, :currency => "New Turkish Lira", :currency_short => "TRY", :exponent => 2}
        @@currencies << {:iso_code => 532, :currency => "Netherlands Antillian Guilder", :currency_short => "ANG", :exponent => 2}
        @@currencies << {:iso_code => 788, :currency => "Tunisian Dinar", :currency_short => "TND", :exponent => 3}
        @@currencies << {:iso_code => 646, :currency => "Rwanda Franc", :currency_short => "RWF", :exponent => 0}
        @@currencies << {:iso_code => 504, :currency => "Moroccan Dirham", :currency_short => "MAD", :exponent => 2}
        @@currencies << {:iso_code => 174, :currency => "Comoro Franc", :currency_short => "KMF", :exponent => 0}
        @@currencies << {:iso_code => 484, :currency => "Mexican Peso", :currency_short => "MXN", :exponent => 2}
        @@currencies << {:iso_code => 478, :currency => "Ouguiya", :currency_short => "MRO", :exponent => 2}
        @@currencies << {:iso_code => 233, :currency => "Kroon", :currency_short => "EEK", :exponent => 2}
        @@currencies << {:iso_code => 400, :currency => "Jordanian Dinar", :currency_short => "JOD", :exponent => 3}
        @@currencies << {:iso_code => 292, :currency => "Gibraltar pound", :currency_short => "GIP", :exponent => 2}
        @@currencies << {:iso_code => 690, :currency => "Seychelles Rupee", :currency_short => "SCR", :exponent => 2}
        @@currencies << {:iso_code => 422, :currency => "Lebanese Pound", :currency_short => "LBP", :exponent => 2}
        @@currencies << {:iso_code => 232, :currency => "Nakfa", :currency_short => "ERN", :exponent => 2}
        @@currencies << {:iso_code => 496, :currency => "Tugrik", :currency_short => "MNT", :exponent => 2}
        @@currencies << {:iso_code => 328, :currency => "Guyana Dollar", :currency_short => "GYD", :exponent => 2}
        @@currencies << {:iso_code => 970, :currency => "Unidad de Valor Real", :currency_short => "COU", :exponent => 2}
        @@currencies << {:iso_code => 974, :currency => "Belarusian Ruble", :currency_short => "BYR", :exponent => 0}
        @@currencies << {:iso_code => 608, :currency => "Philippine Peso", :currency_short => "PHP", :exponent => 2}
        @@currencies << {:iso_code => 598, :currency => "Kina", :currency_short => "PGK", :exponent => 2}
        @@currencies << {:iso_code => 951, :currency => "East Caribbean Dollar", :currency_short => "XCD", :exponent => 2}
        @@currencies << {:iso_code => 52, :currency => "Barbados Dollar", :currency_short => "BBD", :exponent => 2}
        @@currencies << {:iso_code => 944, :currency => "Azerbaijanian Manat", :currency_short => "AZN", :exponent => 2}
        @@currencies << {:iso_code => 434, :currency => "Libyan Dinar", :currency_short => "LYD", :exponent => 3}
        @@currencies << {:iso_code => 706, :currency => "Somali Shilling", :currency_short => "SOS", :exponent => 2}
        @@currencies << {:iso_code => 950, :currency => "CFA Franc BEAC", :currency_short => "XAF", :exponent => 0}
        @@currencies << {:iso_code => 840, :currency => "US Dollar", :currency_short => "USD", :exponent => 2}
        @@currencies << {:iso_code => 68, :currency => "Boliviano", :currency_short => "BOB", :exponent => 2}
        @@currencies << {:iso_code => 214, :currency => "Dominican Peso", :currency_short => "DOP", :exponent => 2}
        @@currencies << {:iso_code => 818, :currency => "Egyptian Pound", :currency_short => "EGP", :exponent => 2}
        @@currencies << {:iso_code => 170, :currency => "Colombian Peso", :currency_short => "COP", :exponent => 2}
        @@currencies << {:iso_code => 986, :currency => "Brazilian Real", :currency_short => "BRL", :exponent => 2}
        @@currencies << {:iso_code => 961, :currency => "Silver (one Troy ounce)", :currency_short => "XAG", :exponent => 0}
        @@currencies << {:iso_code => 973, :currency => "Kwanza", :currency_short => "AOA", :exponent => 2}
        @@currencies << {:iso_code => 962, :currency => "Platinum (one Troy ounce)", :currency_short => "XPT", :exponent => 0}
        @@currencies << {:iso_code => 414, :currency => "Kuwaiti Dinar", :currency_short => "KWD", :exponent => 3}
        @@currencies << {:iso_code => 604, :currency => "Nuevo Sol", :currency_short => "PEN", :exponent => 2}
        @@currencies << {:iso_code => 702, :currency => "Singapore Dollar", :currency_short => "SGD", :exponent => 2}
        @@currencies << {:iso_code => 862, :currency => "Venezuelan bolívar", :currency_short => "VEB", :exponent => 2}
        @@currencies << {:iso_code => 953, :currency => "CFP franc", :currency_short => "XPF", :exponent => 0}
        @@currencies << {:iso_code => 558, :currency => "Cordoba Oro", :currency_short => "NIO", :exponent => 2}
        @@currencies << {:iso_code => 348, :currency => "Forint", :currency_short => "HUF", :exponent => 2}
        @@currencies << {:iso_code => 948, :currency => "WIR Franc ", :currency_short => "CHW", :exponent => 2}
        @@currencies << {:iso_code => 116, :currency => "Riel", :currency_short => "KHR", :exponent => 2}
        @@currencies << {:iso_code => 956, :currency => "European Monetary Unit", :currency_short => "XBB", :exponent => 0}
        @@currencies << {:iso_code => 156, :currency => "Yuan Renminbi", :currency_short => "CNY", :exponent => 2}
        @@currencies << {:iso_code => 834, :currency => "Tanzanian Shilling", :currency_short => "TZS", :exponent => 2}
        @@currencies << {:iso_code => 997, :currency => "", :currency_short => "USN", :exponent => 2}
        @@currencies << {:iso_code => 981, :currency => "Lari", :currency_short => "GEL", :exponent => 2}
        @@currencies << {:iso_code => 242, :currency => "Fiji Dollar", :currency_short => "FJD", :exponent => 2}
        @@currencies << {:iso_code => 941, :currency => "Serbian Dinar", :currency_short => "RSD", :exponent => 2}
        @@currencies << {:iso_code => 104, :currency => "Kyat", :currency_short => "MMK", :exponent => 2}
        @@currencies << {:iso_code => 84, :currency => " Belize Dollar", :currency_short => "BZD", :exponent => 2}
        @@currencies << {:iso_code => 710, :currency => "South African Rand", :currency_short => "ZAR", :exponent => 2}
        @@currencies << {:iso_code => 760, :currency => "Syrian Pound", :currency_short => "SYP", :exponent => 2}
        @@currencies << {:iso_code => 512, :currency => "Rial Omani", :currency_short => "OMR", :exponent => 3}
        @@currencies << {:iso_code => 324, :currency => "Guinea Franc", :currency_short => "GNF", :exponent => 0}
        @@currencies << {:iso_code => 196, :currency => "Cyprus Pound", :currency_short => "CYP", :exponent => 2}
        @@currencies << {:iso_code => 960, :currency => "Special Drawing Rights", :currency_short => "XDR", :exponent => 0}
        @@currencies << {:iso_code => 716, :currency => "Zimbabwe Dollar", :currency_short => "ZWD", :exponent => 2}
        @@currencies << {:iso_code => 972, :currency => "Somoni", :currency_short => "TJS", :exponent => 2}
        @@currencies << {:iso_code => 462, :currency => "Rufiyaa", :currency_short => "MVR", :exponent => 2}
        @@currencies << {:iso_code => 979, :currency => "Mexican Unidad de Inversion (UDI)", :currency_short => "MXV", :exponent => 2}
        @@currencies << {:iso_code => 860, :currency => "Uzbekistan Som", :currency_short => "UZS", :exponent => 2}
        @@currencies << {:iso_code => 12, :currency => "Algerian Dinar", :currency_short => "DZD", :exponent => 2}
        @@currencies << {:iso_code => 332, :currency => "Haiti Gourde", :currency_short => "HTG", :exponent => 2}
        @@currencies << {:iso_code => 963, :currency => "Code reserved for testing purposes", :currency_short => "XTS", :exponent => 0}
        @@currencies << {:iso_code => 32, :currency => "Argentine Peso", :currency_short => "ARS", :exponent => 2}
        @@currencies << {:iso_code => 642, :currency => "Romanian Leu", :currency_short => "ROL", :exponent => 2}
        @@currencies << {:iso_code => 984, :currency => "Bolivian Mvdol (Funds code)", :currency_short => "BOV", :exponent => 2}
        @@currencies << {:iso_code => 440, :currency => "Lithuanian Litas", :currency_short => "LTL", :exponent => 2}
        @@currencies << {:iso_code => 480, :currency => "Mauritius Rupee", :currency_short => "MUR", :exponent => 2}
        @@currencies << {:iso_code => 426, :currency => "Loti", :currency_short => "LSL", :exponent => 2}
        @@currencies << {:iso_code => 262, :currency => "Djibouti Franc", :currency_short => "DJF", :exponent => 0}
        @@currencies << {:iso_code => 886, :currency => "Yemeni Rial", :currency_short => "YER", :exponent => 2}
        @@currencies << {:iso_code => 748, :currency => "Lilangeni", :currency_short => "SZL", :exponent => 2}
        @@currencies << {:iso_code => 192, :currency => "Cuban Peso", :currency_short => "CUP", :exponent => 2}
        @@currencies << {:iso_code => 548, :currency => "Vatu", :currency_short => "VUV", :exponent => 0}
        @@currencies << {:iso_code => 360, :currency => "Rupiah", :currency_short => "IDR", :exponent => 2}
        @@currencies << {:iso_code => 51, :currency => "Armenian Dram", :currency_short => "AMD", :exponent => 2}
        @@currencies << {:iso_code => 894, :currency => "Kwacha", :currency_short => "ZMK", :exponent => 2}
        @@currencies << {:iso_code => 90, :currency => "Solomon Islands Dollar", :currency_short => "SBD", :exponent => 2}
        @@currencies << {:iso_code => 132, :currency => "Cape Verde Escudo", :currency_short => "CVE", :exponent => 2}
        @@currencies << {:iso_code => 999, :currency => "No currency", :currency_short => "XXX", :exponent => 0}
        @@currencies << {:iso_code => 524, :currency => "Nepalese Rupee", :currency_short => "NPR", :exponent => 2}
        @@currencies << {:iso_code => 203, :currency => "Czech Koruna", :currency_short => "CZK", :exponent => 2}
        @@currencies << {:iso_code => 44, :currency => "Bahamian Dollar", :currency_short => "BSD", :exponent => 2}
        @@currencies << {:iso_code => 96, :currency => "Brunei Dollar", :currency_short => "BND", :exponent => 2}
        @@currencies << {:iso_code => 50, :currency => "Bangladeshi Taka", :currency_short => "BDT", :exponent => 2}
        @@currencies << {:iso_code => 404, :currency => "Kenyan Shilling", :currency_short => "KES", :exponent => 2}
        @@currencies << {:iso_code => 947, :currency => "WIR Euro ", :currency_short => "CHE", :exponent => 2}
        @@currencies << {:iso_code => 964, :currency => "Palladium (one Troy ounce)", :currency_short => "XPD", :exponent => 0}
        @@currencies << {:iso_code => 398, :currency => "Tenge", :currency_short => "KZT", :exponent => 2}
        @@currencies << {:iso_code => 352, :currency => "Iceland Krona", :currency_short => "ISK", :exponent => 2}
        @@currencies << {:iso_code => 64, :currency => "Ngultrum", :currency_short => "BTN", :exponent => 2}
        @@currencies << {:iso_code => 533, :currency => "Aruban Guilder", :currency_short => "AWG", :exponent => 2}
        @@currencies << {:iso_code => 230, :currency => "Ethiopian Birr", :currency_short => "ETB", :exponent => 2}
        @@currencies << {:iso_code => 800, :currency => "Uganda Shilling", :currency_short => "UGX", :exponent => 2}
        @@currencies << {:iso_code => 968, :currency => "Surinam Dollar", :currency_short => "SRD", :exponent => 2}
        @@currencies << {:iso_code => 882, :currency => "Samoan Tala", :currency_short => "WST", :exponent => 2}
        @@currencies << {:iso_code => 454, :currency => "Kwacha", :currency_short => "MWK", :exponent => 2}
        @@currencies << {:iso_code => 985, :currency => "Zloty", :currency_short => "PLN", :exponent => 2}
        @@currencies << {:iso_code => 124, :currency => "Canadian Dollar", :currency_short => "CAD", :exponent => 2}
        @@currencies << {:iso_code => 776, :currency => "Pa'anga", :currency_short => "TOP", :exponent => 2}
        @@currencies << {:iso_code => 208, :currency => "Danish Krone", :currency_short => "DKK", :exponent => 2}
        @@currencies << {:iso_code => 108, :currency => "Burundian Franc", :currency_short => "BIF", :exponent => 0}
        @@currencies << {:iso_code => 764, :currency => "Baht", :currency_short => "THB", :exponent => 2}
        @@currencies << {:iso_code => 458, :currency => "Malaysian Ringgit", :currency_short => "MYR", :exponent => 2}
        @@currencies << {:iso_code => 364, :currency => "Iranian Rial", :currency_short => "IRR", :exponent => 2}
        @@currencies << {:iso_code => 600, :currency => "Guarani", :currency_short => "PYG", :exponent => 0}
        @@currencies << {:iso_code => 977, :currency => "Convertible Marks", :currency_short => "BAM", :exponent => 2}
        @@currencies << {:iso_code => 446, :currency => "Pataca", :currency_short => "MOP", :exponent => 2}
        @@currencies << {:iso_code => 780, :currency => "Trinidad and Tobago Dollar", :currency_short => "TTD", :exponent => 2}
        @@currencies << {:iso_code => 703, :currency => "Slovak Koruna", :currency_short => "SKK", :exponent => 2}
        @@currencies << {:iso_code => 958, :currency => "European Unit of Account 17 (E.U.A.-17)", :currency_short => "XBD", :exponent => 0}
        @@currencies << {:iso_code => 430, :currency => "Liberian Dollar", :currency_short => "LRD", :exponent => 2}
        @@currencies << {:iso_code => 191, :currency => "Croatian Kuna", :currency_short => "HRK", :exponent => 2}
        @@currencies << {:iso_code => 694, :currency => "Leone", :currency_short => "SLL", :exponent => 2}
        @@currencies << {:iso_code => 756, :currency => "Swiss Franc", :currency_short => "CHF", :exponent => 2}
        @@currencies << {:iso_code => 969, :currency => "Malagasy Ariary", :currency_short => "MGA", :exponent => 0}
        @@currencies << {:iso_code => 270, :currency => "Dalasi", :currency_short => "GMD", :exponent => 2}
        @@currencies << {:iso_code => 418, :currency => "Kip", :currency_short => "LAK", :exponent => 2}
        @@currencies << {:iso_code => 516, :currency => "Namibian Dollar", :currency_short => "NAD", :exponent => 2}
        @@currencies << {:iso_code => 392, :currency => "Japanese yen", :currency_short => "JPY", :exponent => 0}
        @@currencies << {:iso_code => 320, :currency => "Quetzal", :currency_short => "GTQ", :exponent => 2}
        @@currencies << {:iso_code => 554, :currency => "New Zealand Dollar", :currency_short => "NZD", :exponent => 2}
        @@currencies << {:iso_code => 578, :currency => "Norwegian Krone", :currency_short => "NOK", :exponent => 2}
        @@currencies << {:iso_code => 376, :currency => "New Israeli Shekel", :currency_short => "ILS", :exponent => 2}
        @@currencies << {:iso_code => 957, :currency => "European Unit of Account 9 (E.U.A.-9)", :currency_short => "XBC", :exponent => 0}
        @@currencies << {:iso_code => 498, :currency => "Moldovan Leu", :currency_short => "MDL", :exponent => 2}
        @@currencies << {:iso_code => 998, :currency => "", :currency_short => "USS", :exponent => 2}
        @@currencies << {:iso_code => 955, :currency => "European Composite Unit (EURCO)", :currency_short => "XBA", :exponent => 0}
        @@currencies << {:iso_code => 344, :currency => "Hong Kong Dollar", :currency_short => "HKD", :exponent => 2}
        @@currencies << {:iso_code => 417, :currency => "Som", :currency_short => "KGS", :exponent => 2}
        @@currencies << {:iso_code => 858, :currency => "Peso Uruguayo", :currency_short => "UYU", :exponent => 2}
        @@currencies << {:iso_code => 60, :currency => "Bermudian Dollar ", :currency_short => "BMD", :exponent => 2}
        @@currencies << {:iso_code => 682, :currency => "Saudi Riyal", :currency_short => "SAR", :exponent => 2}
        @@currencies << {:iso_code => 643, :currency => "Russian Ruble", :currency_short => "RUB", :exponent => 2}
        @@currencies << {:iso_code => 470, :currency => "Maltese Lira", :currency_short => "MTL", :exponent => 2}
        @@currencies << {:iso_code => 340, :currency => "Lempira", :currency_short => "HNL", :exponent => 2}
        @@currencies << {:iso_code => 72, :currency => "Pula", :currency_short => "BWP", :exponent => 2}
        @@currencies << {:iso_code => 368, :currency => "Iraqi Dinar", :currency_short => "IQD", :exponent => 3}
        @@currencies << {:iso_code => 188, :currency => "Costa Rican Colon", :currency_short => "CRC", :exponent => 2}
        @@currencies << {:iso_code => 144, :currency => "Sri Lanka Rupee", :currency_short => "LKR", :exponent => 2}
        @@currencies << {:iso_code => 752, :currency => "Swedish Krona", :currency_short => "SEK", :exponent => 2}
        @@currencies << {:iso_code => 136, :currency => "Cayman Islands Dollar", :currency_short => "KYD", :exponent => 2}
        @@currencies << {:iso_code => 8, :currency => "Lek", :currency_short => "ALL", :exponent => 2}
        @@currencies << {:iso_code => 48, :currency => "Bahraini Dinar", :currency_short => "BHD", :exponent => 3}
        @@currencies << {:iso_code => 795, :currency => "Manat", :currency_short => "TMM", :exponent => 2}
        @@currencies << {:iso_code => 938, :currency => "Sudanese Pound", :currency_short => "SDG", :exponent => 2}
        @@currencies << {:iso_code => 590, :currency => "Balboa", :currency_short => "PAB", :exponent => 2}
        @@currencies << {:iso_code => 152, :currency => "Chilean Peso", :currency_short => "CLP", :exponent => 0}
        @@currencies << {:iso_code => 980, :currency => "Hryvnia", :currency_short => "UAH", :exponent => 2}
        @@currencies << {:iso_code => 428, :currency => "Latvian Lats", :currency_short => "LVL", :exponent => 2}
        @@currencies << {:iso_code => 288, :currency => "Cedi", :currency_short => "GHS", :exponent => 2}
        @@currencies << {:iso_code => 978, :currency => "Euro", :currency_short => "EUR", :exponent => 2}
        @@currencies << {:iso_code => 976, :currency => "Franc Congolais", :currency_short => "CDF", :exponent => 2}
        @@currencies << {:iso_code => 586, :currency => "Pakistan Rupee", :currency_short => "PKR", :exponent => 2}
        @@currencies << {:iso_code => 408, :currency => "North Korean Won", :currency_short => "KPW", :exponent => 2}
        @@currencies << {:iso_code => 388, :currency => "Jamaican Dollar", :currency_short => "JMD", :exponent => 2}
        @@currencies << {:iso_code => 990, :currency => "Unidades de formento", :currency_short => "CLF", :exponent => 0}
        @@currencies << {:iso_code => 971, :currency => "Afghani", :currency_short => "AFN", :exponent => 2}
        @@currencies << {:iso_code => 975, :currency => "Bulgarian Lev", :currency_short => "BGN", :exponent => 2}
        @@currencies << {:iso_code => 36, :currency => "Australian Dollar", :currency_short => "AUD", :exponent => 2}
        @@currencies << {:iso_code => 238, :currency => "Falkland Islands Pound", :currency_short => "FKP", :exponent => 2}
        @@currencies << {:iso_code => 901, :currency => "New Taiwan Dollar", :currency_short => "TWD", :exponent => 2}
        @@currencies << {:iso_code => 784, :currency => "United Arab Emirates dirham", :currency_short => "AED", :exponent => 2}
        
        def self.get_ISO_code_from_short(currency_short)
          @@currencies.each do |currency|
            if(currency[:currency_short] == currency_short)
              return currency[:iso_code]
            end
          end
          #if no currency found with that shortcode then return default
          return 826
        end
        
        def self.get_exponent_from_ISO_code(iso_code)
          @@currencies.each do |currency|
            if(currency[iso_code] == iso_code)
              return currency[:exponent]
            end
          end
          #if no currency found with that ISO code then return default
          return 2
        end
        
        def self.get_short_from_ISO_code(iso_code)
          @@currencies.each do |currency|
            if(currency[:iso_code] == iso_code)
              return currency[:currency_short]
            end
          end
          #if no currency found with that ISO code then return default
          return "GBP"
        end
        
      end

      class ISOCountries

        @@countries = Array.new
        @@countries << {:iso_code => 826, :country_short_2 => "GB", :country_short_3 =>  "GBR", :country_name => "United Kingdom", :list_priority => 3}
        @@countries << {:iso_code => 840, :country_short_2 => "US", :country_short_3 =>"USA", :country_name => "United States", :list_priority => 2}
        @@countries << {:iso_code => 36, :country_short_2 => "AU", :country_short_3 =>"AUS", :country_name => "Australia", :list_priority => 1}
        @@countries << {:iso_code => 124, :country_short_2 => "CA", :country_short_3 =>"CAN", :country_name => "Canada", :list_priority => 1}
        @@countries << {:iso_code => 276, :country_short_2 => "DE", :country_short_3 =>"DEU", :country_name => "Germany", :list_priority => 1}
        @@countries << {:iso_code => 250, :country_short_2 => "FR", :country_short_3 =>"FRA", :country_name => "France", :list_priority => 1}
        @@countries << {:iso_code => 533, :country_short_2 => "AW", :country_short_3 =>"ABW", :country_name => "Aruba", :list_priority => 0}
        @@countries << {:iso_code => 4, :country_short_2 => "AF", :country_short_3 =>"AFG", :country_name => "Afghanistan", :list_priority => 0}
        @@countries << {:iso_code => 24, :country_short_2 => "AO", :country_short_3 =>"AGO", :country_name => "Angola", :list_priority => 0}
        @@countries << {:iso_code => 660, :country_short_2 => "AI", :country_short_3 =>"AIA", :country_name => "Anguilla", :list_priority => 0}
        @@countries << {:iso_code => 248, :country_short_2 => "AX", :country_short_3 => "ALA", :country_name => "Åland Islands", :list_priority => 0}
        @@countries << {:iso_code => 8, :country_short_2 => "AL", :country_short_3 =>"ALB", :country_name => "Albania", :list_priority => 0}
        @@countries << {:iso_code => 20, :country_short_2 => "AD", :country_short_3 =>"AND", :country_name => "Andorra", :list_priority => 0}
        @@countries << {:iso_code => 530, :country_short_2 => "AN", :country_short_3 =>"ANT", :country_name => "Netherlands Antilles", :list_priority => 0}
        @@countries << {:iso_code => 784, :country_short_2 => "AE", :country_short_3 =>"ARE", :country_name => "United Arab Emirates", :list_priority => 0}
        @@countries << {:iso_code => 32, :country_short_2 => "AR", :country_short_3 =>"ARG", :country_name => "Argentina", :list_priority => 0}
        @@countries << {:iso_code => 51, :country_short_2 => "AM", :country_short_3 =>"ARM", :country_name => "Armenia", :list_priority => 0}
        @@countries << {:iso_code => 16, :country_short_2 => "AS", :country_short_3 =>"ASM", :country_name => "American Samoa", :list_priority => 0}
        @@countries << {:iso_code => 10, :country_short_2 => "AQ", :country_short_3 =>"ATA", :country_name => "Antarctica", :list_priority => 0}
        @@countries << {:iso_code => 260, :country_short_2 => "TF", :country_short_3 =>"ATF", :country_name => "French Southern Territories", :list_priority => 0}
        @@countries << {:iso_code => 28, :country_short_2 => "AG", :country_short_3 =>"ATG", :country_name => "Antigua and Barbuda", :list_priority => 0}
        @@countries << {:iso_code => 40, :country_short_2 => "AT", :country_short_3 =>"AUT", :country_name => "Austria", :list_priority => 0}
        @@countries << {:iso_code => 31, :country_short_2 => "AZ", :country_short_3 =>"AZE", :country_name => "Azerbaijan", :list_priority => 0}
        @@countries << {:iso_code => 108, :country_short_2 => "BI", :country_short_3 =>"BDI", :country_name => "Burundi", :list_priority => 0}
        @@countries << {:iso_code => 56, :country_short_2 => "BE", :country_short_3 =>"BEL", :country_name => "Belgium", :list_priority => 0}
        @@countries << {:iso_code => 204, :country_short_2 => "BJ", :country_short_3 =>"BEN", :country_name => "Benin", :list_priority => 0}
        @@countries << {:iso_code => 854, :country_short_2 => "BF", :country_short_3 =>"BFA", :country_name => "Burkina Faso", :list_priority => 0}
        @@countries << {:iso_code => 50, :country_short_2 => "BD", :country_short_3 =>"BGD", :country_name => "Bangladesh", :list_priority => 0}
        @@countries << {:iso_code => 100, :country_short_2 => "BG", :country_short_3 =>"BGR", :country_name => "Bulgaria", :list_priority => 0}
        @@countries << {:iso_code => 48, :country_short_2 => "BH", :country_short_3 =>"BHR", :country_name => "Bahrain", :list_priority => 0}
        @@countries << {:iso_code => 44, :country_short_2 => "BS", :country_short_3 =>"BHS", :country_name => "Bahamas", :list_priority => 0}
        @@countries << {:iso_code => 70, :country_short_2 => "BA", :country_short_3 =>"BIH", :country_name => "Bosnia and Herzegovina", :list_priority => 0}
        @@countries << {:iso_code => 652, :country_short_2 => "BL", :country_short_3 => "BLM", :country_name => "Saint Barthélemy", :list_priority => 0}
        @@countries << {:iso_code => 112, :country_short_2 => "BY", :country_short_3 =>"BLR", :country_name => "Belarus", :list_priority => 0}
        @@countries << {:iso_code => 84, :country_short_2 => "BZ", :country_short_3 =>"BLZ", :country_name => "Belize", :list_priority => 0}
        @@countries << {:iso_code => 60, :country_short_2 => "BM", :country_short_3 =>"BMU", :country_name => "Bermuda", :list_priority => 0}
        @@countries << {:iso_code => 68, :country_short_2 => "BO", :country_short_3 =>"BOL", :country_name => "Bolivia", :list_priority => 0}
        @@countries << {:iso_code => 76, :country_short_2 => "BR", :country_short_3 =>"BRA", :country_name => "Brazil", :list_priority => 0}
        @@countries << {:iso_code => 52, :country_short_2 => "BB", :country_short_3 =>"BRB", :country_name => "Barbados", :list_priority => 0}
        @@countries << {:iso_code => 96, :country_short_2 => "BN", :country_short_3 =>"BRN", :country_name => "Brunei Darussalam", :list_priority => 0}
        @@countries << {:iso_code => 64, :country_short_2 => "BT", :country_short_3 =>"BTN", :country_name => "Bhutan", :list_priority => 0}
        @@countries << {:iso_code => 74, :country_short_2 => "BV", :country_short_3 =>"BVT", :country_name => "Bouvet Island", :list_priority => 0}
        @@countries << {:iso_code => 72, :country_short_2 => "BW", :country_short_3 =>"BWA", :country_name => "Botswana", :list_priority => 0}
        @@countries << {:iso_code => 140, :country_short_2 => "CF", :country_short_3 =>"CAF", :country_name => "Central African Republic", :list_priority => 0}
        @@countries << {:iso_code => 166, :country_short_2 => "CC", :country_short_3 => "CCK", :country_name => "Cocos (Keeling}) Islands", :list_priority => 0}
        @@countries << {:iso_code => 756, :country_short_2 => "CH", :country_short_3 =>"CHE", :country_name => "Switzerland", :list_priority => 0}
        @@countries << {:iso_code => 152, :country_short_2 => "CL", :country_short_3 =>"CHL", :country_name => "Chile", :list_priority => 0}
        @@countries << {:iso_code => 156, :country_short_2 => "CN", :country_short_3 =>"CHN", :country_name => "China", :list_priority => 0}
        @@countries << {:iso_code => 384, :country_short_2 => "CI", :country_short_3 => "CIV", :country_name => "Côte d'Ivoire", :list_priority => 0}
        @@countries << {:iso_code => 120, :country_short_2 => "CM", :country_short_3 =>"CMR", :country_name => "Cameroon", :list_priority => 0}
        @@countries << {:iso_code => 180, :country_short_2 => "CD", :country_short_3 => "COD", :country_name => "Congo,  the Democratic Republic of the", :list_priority => 0}
        @@countries << {:iso_code => 178, :country_short_2 => "CG", :country_short_3 =>"COG", :country_name => "Congo", :list_priority => 0}
        @@countries << {:iso_code => 184, :country_short_2 => "CK", :country_short_3 =>"COK", :country_name => "Cook Islands", :list_priority => 0}
        @@countries << {:iso_code => 170, :country_short_2 => "CO", :country_short_3 =>"COL", :country_name => "Colombia", :list_priority => 0}
        @@countries << {:iso_code => 174, :country_short_2 => "KM", :country_short_3 =>"COM", :country_name => "Comoros", :list_priority => 0}
        @@countries << {:iso_code => 132, :country_short_2 => "CV", :country_short_3 =>"CPV", :country_name => "Cape Verde", :list_priority => 0}
        @@countries << {:iso_code => 188, :country_short_2 => "CR", :country_short_3 =>"CRI", :country_name => "Costa Rica", :list_priority => 0}
        @@countries << {:iso_code => 192, :country_short_2 => "CU", :country_short_3 =>"CUB", :country_name => "Cuba", :list_priority => 0}
        @@countries << {:iso_code => 162, :country_short_2 => "CX", :country_short_3 =>"CXR", :country_name => "Christmas Island", :list_priority => 0}
        @@countries << {:iso_code => 136, :country_short_2 => "KY", :country_short_3 =>"CYM", :country_name => "Cayman Islands", :list_priority => 0}
        @@countries << {:iso_code => 196, :country_short_2 => "CY", :country_short_3 =>"CYP", :country_name => "Cyprus", :list_priority => 0}
        @@countries << {:iso_code => 203, :country_short_2 => "CZ", :country_short_3 =>"CZE", :country_name => "Czech Republic", :list_priority => 0}
        @@countries << {:iso_code => 262, :country_short_2 => "DJ", :country_short_3 =>"DJI", :country_name => "Djibouti", :list_priority => 0}
        @@countries << {:iso_code => 212, :country_short_2 => "DM", :country_short_3 =>"DMA", :country_name => "Dominica", :list_priority => 0}
        @@countries << {:iso_code => 208, :country_short_2 => "DK", :country_short_3 =>"DNK", :country_name => "Denmark", :list_priority => 0}
        @@countries << {:iso_code => 214, :country_short_2 => "DO", :country_short_3 =>"DOM", :country_name => "Dominican Republic", :list_priority => 0}
        @@countries << {:iso_code => 12, :country_short_2 => "DZ", :country_short_3 =>"DZA", :country_name => "Algeria", :list_priority => 0}
        @@countries << {:iso_code => 218, :country_short_2 => "EC", :country_short_3 =>"ECU", :country_name => "Ecuador", :list_priority => 0}
        @@countries << {:iso_code => 818, :country_short_2 => "EG", :country_short_3 =>"EGY", :country_name => "Egypt", :list_priority => 0}
        @@countries << {:iso_code => 232, :country_short_2 => "ER", :country_short_3 =>"ERI", :country_name => "Eritrea", :list_priority => 0}
        @@countries << {:iso_code => 732, :country_short_2 => "EH", :country_short_3 =>"ESH", :country_name => "Western Sahara", :list_priority => 0}
        @@countries << {:iso_code => 724, :country_short_2 => "ES", :country_short_3 =>"ESP", :country_name => "Spain", :list_priority => 0}
        @@countries << {:iso_code => 233, :country_short_2 => "EE", :country_short_3 =>"EST", :country_name => "Estonia", :list_priority => 0}
        @@countries << {:iso_code => 231, :country_short_2 => "ET", :country_short_3 =>"ETH", :country_name => "Ethiopia", :list_priority => 0}
        @@countries << {:iso_code => 246, :country_short_2 => "FI", :country_short_3 =>"FIN", :country_name => "Finland", :list_priority => 0}
        @@countries << {:iso_code => 242, :country_short_2 => "FJ", :country_short_3 =>"FJI", :country_name => "Fiji", :list_priority => 0}
        @@countries << {:iso_code => 238, :country_short_2 => "FK", :country_short_3 => "FLK", :country_name => "Falkland Islands (Malvinas})", :list_priority => 0}
        @@countries << {:iso_code => 234, :country_short_2 => "FO", :country_short_3 =>"FRO", :country_name => "Faroe Islands", :list_priority => 0}
        @@countries << {:iso_code => 583, :country_short_2 => "FM", :country_short_3 =>"FSM", :country_name => "Micronesia Federated States of", :list_priority => 0}
        @@countries << {:iso_code => 266, :country_short_2 => "GA", :country_short_3 =>"GAB", :country_name => "Gabon", :list_priority => 0}
        @@countries << {:iso_code => 268, :country_short_2 => "GE", :country_short_3 =>"GEO", :country_name => "Georgia", :list_priority => 0}
        @@countries << {:iso_code => 831, :country_short_2 => "GG", :country_short_3 =>"GGY", :country_name => "Guernsey", :list_priority => 0}
        @@countries << {:iso_code => 288, :country_short_2 => "GH", :country_short_3 =>"GHA", :country_name => "Ghana", :list_priority => 0}
        @@countries << {:iso_code => 292, :country_short_2 => "GI", :country_short_3 =>"GIB", :country_name => "Gibraltar", :list_priority => 0}
        @@countries << {:iso_code => 324, :country_short_2 => "GN", :country_short_3 =>"GIN", :country_name => "Guinea", :list_priority => 0}
        @@countries << {:iso_code => 312, :country_short_2 => "GP", :country_short_3 =>"GLP", :country_name => "Guadeloupe", :list_priority => 0}
        @@countries << {:iso_code => 270, :country_short_2 => "GM", :country_short_3 =>"GMB", :country_name => "Gambia", :list_priority => 0}
        @@countries << {:iso_code => 624, :country_short_2 => "GW", :country_short_3 => "GNB", :country_name => "Guinea-Bissau", :list_priority => 0}
        @@countries << {:iso_code => 226, :country_short_2 => "GQ", :country_short_3 =>"GNQ", :country_name => "Equatorial Guinea", :list_priority => 0}
        @@countries << {:iso_code => 300, :country_short_2 => "GR", :country_short_3 =>"GRC", :country_name => "Greece", :list_priority => 0}
        @@countries << {:iso_code => 308, :country_short_2 => "GD", :country_short_3 =>"GRD", :country_name => "Grenada", :list_priority => 0}
        @@countries << {:iso_code => 304, :country_short_2 => "GL", :country_short_3 =>"GRL", :country_name => "Greenland", :list_priority => 0}
        @@countries << {:iso_code => 320, :country_short_2 => "GT", :country_short_3 =>"GTM", :country_name => "Guatemala", :list_priority => 0}
        @@countries << {:iso_code => 254, :country_short_2 => "GF", :country_short_3 =>"GUF", :country_name => "French Guiana", :list_priority => 0}
        @@countries << {:iso_code => 316, :country_short_2 => "GU", :country_short_3 =>"GUM", :country_name => "Guam", :list_priority => 0}
        @@countries << {:iso_code => 328, :country_short_2 => "GY", :country_short_3 =>"GUY", :country_name => "Guyana", :list_priority => 0}
        @@countries << {:iso_code => 344, :country_short_2 => "HK", :country_short_3 =>"HKG", :country_name => "Hong Kong", :list_priority => 0}
        @@countries << {:iso_code => 334, :country_short_2 => "HM", :country_short_3 =>"HMD", :country_name => "Heard Island and McDonald Islands", :list_priority => 0}
        @@countries << {:iso_code => 340, :country_short_2 => "HN", :country_short_3 =>"HND", :country_name => "Honduras", :list_priority => 0}
        @@countries << {:iso_code => 191, :country_short_2 => "HR", :country_short_3 =>"HRV", :country_name => "Croatia", :list_priority => 0}
        @@countries << {:iso_code => 332, :country_short_2 => "HT", :country_short_3 =>"HTI", :country_name => "Haiti", :list_priority => 0}
        @@countries << {:iso_code => 348, :country_short_2 => "HU", :country_short_3 =>"HUN", :country_name => "Hungary", :list_priority => 0}
        @@countries << {:iso_code => 360, :country_short_2 => "ID", :country_short_3 =>"IDN", :country_name => "Indonesia", :list_priority => 0}
        @@countries << {:iso_code => 833, :country_short_2 => "IM", :country_short_3 =>"IMN", :country_name => "Isle of Man", :list_priority => 0}
        @@countries << {:iso_code => 356, :country_short_2 => "IN", :country_short_3 =>"IND", :country_name => "India", :list_priority => 0}
        @@countries << {:iso_code => 86, :country_short_2 => "IO", :country_short_3 =>"IOT", :country_name => "British Indian Ocean Territory", :list_priority => 0}
        @@countries << {:iso_code => 372, :country_short_2 => "IE", :country_short_3 =>"IRL", :country_name => "Ireland", :list_priority => 0}
        @@countries << {:iso_code => 364, :country_short_2 => "IR", :country_short_3 =>"IRN", :country_name => "Iran Islamic Republic of", :list_priority => 0}
        @@countries << {:iso_code => 368, :country_short_2 => "IQ", :country_short_3 =>"IRQ", :country_name => "Iraq", :list_priority => 0}
        @@countries << {:iso_code => 352, :country_short_2 => "IS", :country_short_3 =>"ISL", :country_name => "Iceland", :list_priority => 0}
        @@countries << {:iso_code => 376, :country_short_2 => "IL", :country_short_3 =>"ISR", :country_name => "Israel", :list_priority => 0}
        @@countries << {:iso_code => 380, :country_short_2 => "IT", :country_short_3 =>"ITA", :country_name => "Italy", :list_priority => 0}
        @@countries << {:iso_code => 388, :country_short_2 => "JM", :country_short_3 =>"JAM", :country_name => "Jamaica", :list_priority => 0}
        @@countries << {:iso_code => 832, :country_short_2 => "JE", :country_short_3 =>"JEY", :country_name => "Jersey", :list_priority => 0}
        @@countries << {:iso_code => 400, :country_short_2 => "JO", :country_short_3 =>"JOR", :country_name => "Jordan", :list_priority => 0}
        @@countries << {:iso_code => 392, :country_short_2 => "JP", :country_short_3 =>"JPN", :country_name => "Japan", :list_priority => 0}
        @@countries << {:iso_code => 398, :country_short_2 => "KZ", :country_short_3 =>"KAZ", :country_name => "Kazakhstan", :list_priority => 0}
        @@countries << {:iso_code => 404, :country_short_2 => "KE", :country_short_3 =>"KEN", :country_name => "Kenya", :list_priority => 0}
        @@countries << {:iso_code => 417, :country_short_2 => "KG", :country_short_3 =>"KGZ", :country_name => "Kyrgyzstan", :list_priority => 0}
        @@countries << {:iso_code => 116, :country_short_2 => "KH", :country_short_3 =>"KHM", :country_name => "Cambodia", :list_priority => 0}
        @@countries << {:iso_code => 296, :country_short_2 => "KI", :country_short_3 =>"KIR", :country_name => "Kiribati", :list_priority => 0}
        @@countries << {:iso_code => 659, :country_short_2 => "KN", :country_short_3 =>"KNA", :country_name => "Saint Kitts and Nevis", :list_priority => 0}
        @@countries << {:iso_code => 410, :country_short_2 => "KR", :country_short_3 => "KOR", :country_name => "Korea, Republic of", :list_priority => 0}
        @@countries << {:iso_code => 414, :country_short_2 => "KW", :country_short_3 =>"KWT", :country_name => "Kuwait", :list_priority => 0}
        @@countries << {:iso_code => 418, :country_short_2 => "LA", :country_short_3 => "LAO", :country_name => "Lao People's Democratic Republic", :list_priority => 0}
        @@countries << {:iso_code => 422, :country_short_2 => "LB", :country_short_3 =>"LBN", :country_name => "Lebanon", :list_priority => 0}
        @@countries << {:iso_code => 430, :country_short_2 => "LR", :country_short_3 =>"LBR", :country_name => "Liberia", :list_priority => 0}
        @@countries << {:iso_code => 434, :country_short_2 => "LY", :country_short_3 =>"LBY", :country_name => "Libyan Arab Jamahiriya", :list_priority => 0}
        @@countries << {:iso_code => 662, :country_short_2 => "LC", :country_short_3 =>"LCA", :country_name => "Saint Lucia", :list_priority => 0}
        @@countries << {:iso_code => 438, :country_short_2 => "LI", :country_short_3 =>"LIE", :country_name => "Liechtenstein", :list_priority => 0}
        @@countries << {:iso_code => 144, :country_short_2 => "LK", :country_short_3 =>"LKA", :country_name => "Sri Lanka", :list_priority => 0}
        @@countries << {:iso_code => 426, :country_short_2 => "LS", :country_short_3 =>"LSO", :country_name => "Lesotho", :list_priority => 0}
        @@countries << {:iso_code => 440, :country_short_2 => "LT", :country_short_3 =>"LTU", :country_name => "Lithuania", :list_priority => 0}
        @@countries << {:iso_code => 442, :country_short_2 => "LU", :country_short_3 =>"LUX", :country_name => "Luxembourg", :list_priority => 0}
        @@countries << {:iso_code => 428, :country_short_2 => "LV", :country_short_3 =>"LVA", :country_name => "Latvia", :list_priority => 0}
        @@countries << {:iso_code => 446, :country_short_2 => "MO", :country_short_3 =>"MAC", :country_name => "Macao", :list_priority => 0}
        @@countries << {:iso_code => 663, :country_short_2 => "MF", :country_short_3 => "MAF", :country_name => "Saint Martin (French part})", :list_priority => 0}
        @@countries << {:iso_code => 504, :country_short_2 => "MA", :country_short_3 =>"MAR", :country_name => "Morocco", :list_priority => 0}
        @@countries << {:iso_code => 492, :country_short_2 => "MC", :country_short_3 =>"MCO", :country_name => "Monaco", :list_priority => 0}
        @@countries << {:iso_code => 498, :country_short_2 => "MD", :country_short_3 =>"MDA", :country_name => "Moldova", :list_priority => 0}
        @@countries << {:iso_code => 450, :country_short_2 => "MG", :country_short_3 =>"MDG", :country_name => "Madagascar", :list_priority => 0}
        @@countries << {:iso_code => 462, :country_short_2 => "MV", :country_short_3 =>"MDV", :country_name => "Maldives", :list_priority => 0}
        @@countries << {:iso_code => 484, :country_short_2 => "MX", :country_short_3 =>"MEX", :country_name => "Mexico", :list_priority => 0}
        @@countries << {:iso_code => 584, :country_short_2 => "MH", :country_short_3 =>"MHL", :country_name => "Marshall Islands", :list_priority => 0}
        @@countries << {:iso_code => 807, :country_short_2 => "MK", :country_short_3 => "MKD", :country_name => "Macedonia, the former Yugoslav Republic of", :list_priority => 0}
        @@countries << {:iso_code => 466, :country_short_2 => "ML", :country_short_3 =>"MLI", :country_name => "Mali", :list_priority => 0}
        @@countries << {:iso_code => 470, :country_short_2 => "MT", :country_short_3 =>"MLT", :country_name => "Malta", :list_priority => 0}
        @@countries << {:iso_code => 104, :country_short_2 => "MM", :country_short_3 =>"MMR", :country_name => "Myanmar", :list_priority => 0}
        @@countries << {:iso_code => 499, :country_short_2 => "ME", :country_short_3 =>"MNE", :country_name => "Montenegro", :list_priority => 0}
        @@countries << {:iso_code => 496, :country_short_2 => "MN", :country_short_3 =>"MNG", :country_name => "Mongolia", :list_priority => 0}
        @@countries << {:iso_code => 580, :country_short_2 => "MP", :country_short_3 =>"MNP", :country_name => "Northern Mariana Islands", :list_priority => 0}
        @@countries << {:iso_code => 508, :country_short_2 => "MZ", :country_short_3 =>"MOZ", :country_name => "Mozambique", :list_priority => 0}
        @@countries << {:iso_code => 478, :country_short_2 => "MR", :country_short_3 =>"MRT", :country_name => "Mauritania", :list_priority => 0}
        @@countries << {:iso_code => 500, :country_short_2 => "MS", :country_short_3 =>"MSR", :country_name => "Montserrat", :list_priority => 0}
        @@countries << {:iso_code => 474, :country_short_2 => "MQ", :country_short_3 =>"MTQ", :country_name => "Martinique", :list_priority => 0}
        @@countries << {:iso_code => 480, :country_short_2 => "MU", :country_short_3 =>"MUS", :country_name => "Mauritius", :list_priority => 0}
        @@countries << {:iso_code => 454, :country_short_2 => "MW", :country_short_3 =>"MWI", :country_name => "Malawi", :list_priority => 0}
        @@countries << {:iso_code => 458, :country_short_2 => "MY", :country_short_3 =>"MYS", :country_name => "Malaysia", :list_priority => 0}
        @@countries << {:iso_code => 175, :country_short_2 => "YT", :country_short_3 =>"MYT", :country_name => "Mayotte", :list_priority => 0}
        @@countries << {:iso_code => 516, :country_short_2 => "NA", :country_short_3 =>"NAM", :country_name => "Namibia", :list_priority => 0}
        @@countries << {:iso_code => 540, :country_short_2 => "NC", :country_short_3 =>"NCL", :country_name => "New Caledonia", :list_priority => 0}
        @@countries << {:iso_code => 562, :country_short_2 => "NE", :country_short_3 =>"NER", :country_name => "Niger", :list_priority => 0}
        @@countries << {:iso_code => 574, :country_short_2 => "NF", :country_short_3 =>"NFK", :country_name => "Norfolk Island", :list_priority => 0}
        @@countries << {:iso_code => 566, :country_short_2 => "NG", :country_short_3 =>"NGA", :country_name => "Nigeria", :list_priority => 0}
        @@countries << {:iso_code => 558, :country_short_2 => "NI", :country_short_3 =>"NIC", :country_name => "Nicaragua", :list_priority => 0}
        @@countries << {:iso_code => 570, :country_short_2 => "NU", :country_short_3 =>"NIU", :country_name => "Niue", :list_priority => 0}
        @@countries << {:iso_code => 528, :country_short_2 => "NL", :country_short_3 =>"NLD", :country_name => "Netherlands", :list_priority => 0}
        @@countries << {:iso_code => 578, :country_short_2 => "NO", :country_short_3 =>"NOR", :country_name => "Norway", :list_priority => 0}
        @@countries << {:iso_code => 524, :country_short_2 => "NP", :country_short_3 =>"NPL", :country_name => "Nepal", :list_priority => 0}
        @@countries << {:iso_code => 520, :country_short_2 => "NR", :country_short_3 =>"NRU", :country_name => "Nauru", :list_priority => 0}
        @@countries << {:iso_code => 554, :country_short_2 => "NZ", :country_short_3 =>"NZL", :country_name => "New Zealand", :list_priority => 0}
        @@countries << {:iso_code => 512, :country_short_2 => "OM", :country_short_3 =>"OMN", :country_name => "Oman", :list_priority => 0}
        @@countries << {:iso_code => 586, :country_short_2 => "PK", :country_short_3 =>"PAK", :country_name => "Pakistan", :list_priority => 0}
        @@countries << {:iso_code => 591, :country_short_2 => "PA", :country_short_3 =>"PAN", :country_name => "Panama", :list_priority => 0}
        @@countries << {:iso_code => 612, :country_short_2 => "PN", :country_short_3 =>"PCN", :country_name => "Pitcairn", :list_priority => 0}
        @@countries << {:iso_code => 604, :country_short_2 => "PE", :country_short_3 =>"PER", :country_name => "Peru", :list_priority => 0}
        @@countries << {:iso_code => 608, :country_short_2 => "PH", :country_short_3 =>"PHL", :country_name => "Philippines", :list_priority => 0}
        @@countries << {:iso_code => 585, :country_short_2 => "PW", :country_short_3 =>"PLW", :country_name => "Palau", :list_priority => 0}
        @@countries << {:iso_code => 598, :country_short_2 => "PG", :country_short_3 =>"PNG", :country_name => "Papua New Guinea", :list_priority => 0}
        @@countries << {:iso_code => 616, :country_short_2 => "PL", :country_short_3 =>"POL", :country_name => "Poland", :list_priority => 0}
        @@countries << {:iso_code => 630, :country_short_2 => "PR", :country_short_3 =>"PRI", :country_name => "Puerto Rico", :list_priority => 0}
        @@countries << {:iso_code => 408, :country_short_2 => "KP", :country_short_3 => "PRK", :country_name => "Korea, Democratic People's Republic of", :list_priority => 0}
        @@countries << {:iso_code => 620, :country_short_2 => "PT", :country_short_3 =>"PRT", :country_name => "Portugal", :list_priority => 0}
        @@countries << {:iso_code => 600, :country_short_2 => "PY", :country_short_3 =>"PRY", :country_name => "Paraguay", :list_priority => 0}
        @@countries << {:iso_code => 275, :country_short_2 => "PS", :country_short_3 => "PSE", :country_name => "Palestinian Territory,  Occupied", :list_priority => 0}
        @@countries << {:iso_code => 258, :country_short_2 => "PF", :country_short_3 =>"PYF", :country_name => "French Polynesia", :list_priority => 0}
        @@countries << {:iso_code => 634, :country_short_2 => "QA", :country_short_3 =>"QAT", :country_name => "Qatar", :list_priority => 0}
        @@countries << {:iso_code => 638, :country_short_2 => "RE", :country_short_3 => "REU", :country_name => "Réunion", :list_priority => 0}
        @@countries << {:iso_code => 642, :country_short_2 => "RO", :country_short_3 =>"ROU", :country_name => "Romania", :list_priority => 0}
        @@countries << {:iso_code => 643, :country_short_2 => "RU", :country_short_3 =>"RUS", :country_name => "Russian Federation", :list_priority => 0}
        @@countries << {:iso_code => 646, :country_short_2 => "RW", :country_short_3 =>"RWA", :country_name => "Rwanda", :list_priority => 0}
        @@countries << {:iso_code => 682, :country_short_2 => "SA", :country_short_3 =>"SAU", :country_name => "Saudi Arabia", :list_priority => 0}
        @@countries << {:iso_code => 736, :country_short_2 => "SD", :country_short_3 =>"SDN", :country_name => "Sudan", :list_priority => 0}
        @@countries << {:iso_code => 686, :country_short_2 => "SN", :country_short_3 =>"SEN", :country_name => "Senegal", :list_priority => 0}
        @@countries << {:iso_code => 702, :country_short_2 => "SG", :country_short_3 =>"SGP", :country_name => "Singapore", :list_priority => 0}
        @@countries << {:iso_code => 239, :country_short_2 => "GS", :country_short_3 =>"SGS", :country_name => "South Georgia and the South Sandwich Islands", :list_priority => 0}
        @@countries << {:iso_code => 654, :country_short_2 => "SH", :country_short_3 =>"SHN", :country_name => "Saint Helena", :list_priority => 0}
        @@countries << {:iso_code => 744, :country_short_2 => "SJ", :country_short_3 =>"SJM", :country_name => "Svalbard and Jan Mayen", :list_priority => 0}
        @@countries << {:iso_code => 90, :country_short_2 => "SB", :country_short_3 =>"SLB", :country_name => "Solomon Islands", :list_priority => 0}
        @@countries << {:iso_code => 694, :country_short_2 => "SL", :country_short_3 =>"SLE", :country_name => "Sierra Leone", :list_priority => 0}
        @@countries << {:iso_code => 222, :country_short_2 => "SV", :country_short_3 =>"SLV", :country_name => "El Salvador", :list_priority => 0}
        @@countries << {:iso_code => 674, :country_short_2 => "SM", :country_short_3 =>"SMR", :country_name => "San Marino", :list_priority => 0}
        @@countries << {:iso_code => 706, :country_short_2 => "SO", :country_short_3 =>"SOM", :country_name => "Somalia", :list_priority => 0}
        @@countries << {:iso_code => 666, :country_short_2 => "PM", :country_short_3 =>"SPM", :country_name => "Saint Pierre and Miquelon", :list_priority => 0}
        @@countries << {:iso_code => 688, :country_short_2 => "RS", :country_short_3 =>"SRB", :country_name => "Serbia", :list_priority => 0}
        @@countries << {:iso_code => 678, :country_short_2 => "ST", :country_short_3 =>"STP", :country_name => "Sao Tome and Principe", :list_priority => 0}
        @@countries << {:iso_code => 740, :country_short_2 => "SR", :country_short_3 =>"SUR", :country_name => "Suriname", :list_priority => 0}
        @@countries << {:iso_code => 703, :country_short_2 => "SK", :country_short_3 =>"SVK", :country_name => "Slovakia", :list_priority => 0}
        @@countries << {:iso_code => 705, :country_short_2 => "SI", :country_short_3 =>"SVN", :country_name => "Slovenia", :list_priority => 0}
        @@countries << {:iso_code => 752, :country_short_2 => "SE", :country_short_3 =>"SWE", :country_name => "Sweden", :list_priority => 0}
        @@countries << {:iso_code => 748, :country_short_2 => "SZ", :country_short_3 =>"SWZ", :country_name => "Swaziland", :list_priority => 0}
        @@countries << {:iso_code => 690, :country_short_2 => "SC", :country_short_3 =>"SYC", :country_name => "Seychelles", :list_priority => 0}
        @@countries << {:iso_code => 760, :country_short_2 => "SY", :country_short_3 =>"SYR", :country_name => "Syrian Arab Republic", :list_priority => 0}
        @@countries << {:iso_code => 796, :country_short_2 => "TC", :country_short_3 =>"TCA", :country_name => "Turks and Caicos Islands", :list_priority => 0}
        @@countries << {:iso_code => 148, :country_short_2 => "TD", :country_short_3 =>"TCD", :country_name => "Chad", :list_priority => 0}
        @@countries << {:iso_code => 768, :country_short_2 => "TG", :country_short_3 =>"TGO", :country_name => "Togo", :list_priority => 0}
        @@countries << {:iso_code => 764, :country_short_2 => "TH", :country_short_3 =>"THA", :country_name => "Thailand", :list_priority => 0}
        @@countries << {:iso_code => 762, :country_short_2 => "TJ", :country_short_3 =>"TJK", :country_name => "Tajikistan", :list_priority => 0}
        @@countries << {:iso_code => 772, :country_short_2 => "TK", :country_short_3 =>"TKL", :country_name => "Tokelau", :list_priority => 0}
        @@countries << {:iso_code => 795, :country_short_2 => "TM", :country_short_3 =>"TKM", :country_name => "Turkmenistan", :list_priority => 0}
        @@countries << {:iso_code => 626, :country_short_2 => "TL", :country_short_3 => "TLS", :country_name => "Timor-Leste", :list_priority => 0}
        @@countries << {:iso_code => 776, :country_short_2 => "TO", :country_short_3 =>"TON", :country_name => "Tonga", :list_priority => 0}
        @@countries << {:iso_code => 780, :country_short_2 => "TT", :country_short_3 =>"TTO", :country_name => "Trinidad and Tobago", :list_priority => 0}
        @@countries << {:iso_code => 788, :country_short_2 => "TN", :country_short_3 =>"TUN", :country_name => "Tunisia", :list_priority => 0}
        @@countries << {:iso_code => 792, :country_short_2 => "TR", :country_short_3 =>"TUR", :country_name => "Turkey", :list_priority => 0}
        @@countries << {:iso_code => 798, :country_short_2 => "TV", :country_short_3 =>"TUV", :country_name => "Tuvalu", :list_priority => 0}
        @@countries << {:iso_code => 158, :country_short_2 => "TW", :country_short_3 => "TWN", :country_name => "Taiwan, Province of China", :list_priority => 0}
        @@countries << {:iso_code => 834, :country_short_2 => "TZ", :country_short_3 => "TZA", :country_name => "Tanzania, United Republic of", :list_priority => 0}
        @@countries << {:iso_code => 800, :country_short_2 => "UG", :country_short_3 =>"UGA", :country_name => "Uganda", :list_priority => 0}
        @@countries << {:iso_code => 804, :country_short_2 => "UA", :country_short_3 =>"UKR", :country_name => "Ukraine", :list_priority => 0}
        @@countries << {:iso_code => 581, :country_short_2 => "UM", :country_short_3 =>"UMI", :country_name => "United States Minor Outlying Islands", :list_priority => 0}
        @@countries << {:iso_code => 858, :country_short_2 => "UY", :country_short_3 =>"URY", :country_name => "Uruguay", :list_priority => 0}
        @@countries << {:iso_code => 860, :country_short_2 => "UZ", :country_short_3 =>"UZB", :country_name => "Uzbekistan", :list_priority => 0}
        @@countries << {:iso_code => 336, :country_short_2 => "VA", :country_short_3 => "VAT", :country_name => "Holy See (Vatican City State})", :list_priority => 0}
        @@countries << {:iso_code => 670, :country_short_2 => "VC", :country_short_3 =>"VCT", :country_name => "Saint Vincent and the Grenadines", :list_priority => 0}
        @@countries << {:iso_code => 862, :country_short_2 => "VE", :country_short_3 =>"VEN", :country_name => "Venezuela", :list_priority => 0}
        @@countries << {:iso_code => 92, :country_short_2 => "VG", :country_short_3 => "VGB", :country_name => "Virgin Islands, British", :list_priority => 0}
        @@countries << {:iso_code => 850, :country_short_2 => "VI", :country_short_3 => "VIR", :country_name => "Virgin Islands, U.S.", :list_priority => 0}
        @@countries << {:iso_code => 704, :country_short_2 => "VN", :country_short_3 =>"VNM", :country_name => "Viet Nam", :list_priority => 0}
        @@countries << {:iso_code => 548, :country_short_2 => "VU", :country_short_3 =>"VUT", :country_name => "Vanuatu", :list_priority => 0}
        @@countries << {:iso_code => 876, :country_short_2 => "WF", :country_short_3 =>"WLF", :country_name => "Wallis And Futuna", :list_priority => 0}
        @@countries << {:iso_code => 882, :country_short_2 => "WS", :country_short_3 =>"WSM", :country_name => "Samoa", :list_priority => 0}
        @@countries << {:iso_code => 887, :country_short_2 => "YE", :country_short_3 =>"YEM", :country_name => "Yemen", :list_priority => 0}
        @@countries << {:iso_code => 710, :country_short_2 => "ZA", :country_short_3 =>"ZAF", :country_name => "South Africa", :list_priority => 0}
        @@countries << {:iso_code => 894, :country_short_2 => "ZM", :country_short_3 =>"ZMB", :country_name => "Zambia", :list_priority => 0}
        @@countries << {:iso_code => 826, :country_short_2 => "ZW", :country_short_3 =>"ZWE", :country_name => "Zimbabwe", :list_priority => 0}
        @@countries << {:iso_code => 535, :country_short_2 => "BQ", :country_short_3 => "BES", :country_name => "Bonaire, Sint Eustatius and Saba", :list_priority => 0}
        @@countries << {:iso_code => 531, :country_short_2 => "CW", :country_short_3 => "CUW", :country_name => "Curaçao", :list_priority => 0}
        @@countries << {:iso_code => 534, :country_short_2 => "SX", :country_short_3 => "SXM", :country_name => "Sint Maarten (Dutch part})", :list_priority => 0}
        @@countries << {:iso_code => 728, :country_short_2 => "SS", :country_short_3 =>"SSD", :country_name => "South Sudan", :list_priority => 0}
        
        
        def self.get_ISO_code_from_2_digit_short(country_short_2)
          @@countries.each do |country|
            if(country[:country_short_2] == country_short_2)
              return country[:iso_code]
            end
          end
          return 826
        end
      end
    end
  end
end
