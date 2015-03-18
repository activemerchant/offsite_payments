require "bigdecimal/util"

module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module PayVector

      mattr_accessor :service_url
      self.service_url = 'https://mms.payvector.net/Pages/PublicPages/PaymentForm.aspx'

      def self.notification(post, options = {})
        Notification.new(post, options)
      end

      class Helper < OffsitePayments::Helper
        self.country_format = :numeric

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
        
        def initialize(order, account, options = {})
          #store merchant password and the preSharedKey as private variables so they aren't added to the form
          @merchant_password = options.delete(:credential2)
          @pre_shared_key = options.delete(:credential3)

          order = order.to_s
          options.each do |key, option|
            options[key] = option.to_s
          end

          super

          add_field("OrderDescription", self.application_id + " " + order)

          amount = options[:amount].to_d
          if Money.respond_to? :from_amount
            money = Money.from_amount(amount, options[:currency])
          else
            amount.is_a? Numeric or raise ArgumentError, "'amount' must be numeric"
            currency = Money::Currency.wrap(options[:currency])
            value = amount * currency.subunit_to_unit
            value = value.round unless infinite_precision
            money = Money.new(value, currency)
          end

          #get iso numeric
          self.currency = money.currency.iso_numeric

          add_field("Amount", money.cents)

          transaction_date_time
          populate_fields_with_defaults
        end
            
        def customer(params={})
          add_field(mappings[:customer][:email], params[:email])
          add_field(mappings[:customer][:phone], params[:phone])
          #Concatenate first and last names
          add_field('CustomerName', "#{params[:first_name]} #{params[:last_name]}")
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
          money = Money.new(@params['Amount'].to_d, currency)
          money.to_s
        end
        
        def currency
          if Money::Currency.respond_to? :find_by_iso_numeric
            return Money::Currency.find_by_iso_numeric(@params["CurrencyCode"]).iso_code
          else
            id, _ = Money::Currency.table.find{|key, currency| currency[:iso_numeric] == @params["CurrencyCode"]}
            return Money::Currency.new(id).iso_code
          end
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
    end
  end
end
