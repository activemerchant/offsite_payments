
module OffsitePayments
  module Integrations
    module Paytm
      mattr_accessor :test_url
      self.test_url = "https://pguat.paytm.com/oltp-web/processTransaction"

      mattr_accessor :production_url
      self.production_url = "https://secure.paytm.in/oltp-web/processTransaction"

      def self.service_url
        mode = OffsitePayments.mode
        case mode
        when :production
          self.production_url
        when :test
          self.test_url
        else
          raise StandardError, "Integration mode set to an invalid value: #{mode}"
        end
      end

      def self.helper(order, account, options = {})
        Helper.new(order, account, options)
      end


      class Helper < OffsitePayments::Helper
        def initialize(order, account, options = {})
          merchant_key = options.delete :merchant_key


          device_used      = options.delete(:device_used)
          customer         = options.delete(:customer)
          industry_type_id = options.delete(:industry_type_id)
          website          = options.delete(:website)

          super
          self.device_used      = device_used
          self.customer         = customer
          self.industry_type_id = industry_type_id
          self.website          = website


          # not mentioned in super methods, but mentioned in permitted options
          self.transaction_type = options[:transaction_type] 



          self.checksum = Checksum.create(@fields, merchant_key)
        end


        # Helper.mapping(key, value) is a method for adding Helper.mappings = { key: value }
        mapping :order,   'ORDER_ID' #The “Order ID” is the Merchant’s Transaction ID which should be unique for every transaction.
        mapping :account, 'MID' #This is the “Merchant Identifier” that is issued by Paytm to the Merchant. This is unique for each merchant that integrates with Paytm
        mapping :amount,  'TXN_AMOUNT'

        mapping :notify_url, 'CALLBACK_URL' # ? is notify_url is your app's route that paytm will send a get request to, in order to tell your app that transaction happened.
        # TODO CALLBACK_URL seems to be a return_url instead. 
        # self.notify_url     = options[:notify_url]
        # self.return_url     = options[:return_url]
        # self.redirect_param = options[:redirect_param]

        # # redirects to there instead of http://rivo.herokuapp.com/client/payments/citrus that I sent them accidentally.



        mapping :transaction_type, 'REQUEST_TYPE' #Type of transaction. Possible value: DEFAULT for normal transaction flow, SUBSCRIBE for subscription transaction



        # custom mappings
        mapping :device_used, 'CHANNEL_ID' #Pass the Channel ID, WEB – for desktop websites, WAP – for mobile websites
        # we are grouping custom attributes
        mapping :customer, {
          :email      => 'EMAIL',
          :phone      => 'MOBILE_NO',
          :id         => 'CUST_ID' #The “Customer ID” is the customer identifier. This could be a unique user Id that the Merchant has assigned to its customers.
        }
        mapping :checksum,         'CHECKSUMHASH'

        # provided by paytm
        mapping :industry_type_id, 'INDUSTRY_TYPE_ID'
        mapping :website,          'WEBSITE'

      end

      module Checksum
        class << self


          def create(params_from_form, merchant_key)
            salt = SecureRandom.urlsafe_base64(4*(3.0/4.0))

            checksum = salted_checksum params_from_form, salt

            ### encrypting checksum ###
            Encryption.encrypt_single_value(checksum, merchant_key).gsub("\n",'')
          end


          def verify(params_hash_without_checksum, checksum, merchant_key)
            decrypted_checksum = Encryption.decrypt_single_value(checksum, merchant_key)

            begin
              salt = decrypted_checksum.chars.last(4).join
              generated_checksum = salted_checksum params_hash_without_checksum, salt
            rescue
              return false
            end

            decrypted_checksum == generated_checksum
          end

          private 

            def salted_checksum params_from_form, salt
              str = params_from_form.sort.to_h.values.join('|') + '|' + salt
              generated_checksum = Digest::SHA256.hexdigest(str) + salt
            end

        end

      end

      module Encryption

        class << self

          def encrypt_single_value data, encryption_key
            set_encryption :encrypt, encryption_key

            Base64.encode64( @encryption.update(data) + @encryption.final )
          end


          ### function returns a single decrypted value ###
          ### input data -> value to be decrypted ###
          ### key -> key to use for decryption ###
          def decrypt_single_value(data, encryption_key)
            set_encryption :decrypt, encryption_key
            decrypted_data = Base64.decode64(data.to_s)

            @encryption.update(decrypted_data) + @encryption.final rescue false
          end


          private
            def set_encryption phase, encryption_key
              @encryption = OpenSSL::Cipher::Cipher::AES128.new(:CBC) #that's the algorithm we are using
              @encryption.send phase #setting :encrypt mode, should be first after initialization

              @encryption.iv = '@@@@&&&&####$$$$' #initialization vector
              @encryption.key = encryption_key
            end
        end

      end

      class Notification < OffsitePayments::Notification

        def item_id
          params['ORDERID']
        end

        def status
          params["RESPMSG"]
        end

        def success? 
          params["STATUS"] == "TXN_SUCCESS"
        end

        def failure?
          params["STATUS"] == "TXN_FAILURE"
        end

        def complete?
          params["STATUS"] != "OPEN" # is it about completeness?
        end

        def acknowledge(merchant_key)
          checksum = params.delete 'CHECKSUMHASH'
          # binding.pry
          OffsitePayments::Integrations::Paytm::Checksum.verify(
            params, checksum, merchant_key
          )
        end

        def initialize params
          @params = params
        end

      end


    end
  end
end





# GOTCHAS
# 1. if you are getting 'OOPS Payment failed due to any of these reasons:...' page on posting params, it may be because you are using wrong credentials.
# 2. if page just redirects right away to the notify_url, your item_id may be repeated (should be unique every time, even on test server)

# to get :industry_type_id, :account, etc, sign up on 
# https://seller.paytm.com/login 



