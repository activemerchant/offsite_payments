# With help from Giovanni Intini and his code for RGestPay - http://medlar.it/it/progetti/rgestpay

module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module Gestpay
      mattr_accessor :service_url
      self.service_url = 'https://ecomm.sella.it/gestpay/pagam.asp'

      def self.notification(post, options = {})
        Notification.new(post)
      end

      def self.return(query_string, options = {})
        Return.new(query_string)
      end

      module Common
        GestpayEncryptionResponseError = Class.new(StandardError)

        VERSION = "2.0"
        ENCRYPTION_PATH = "/CryptHTTPS/Encrypt.asp"
        DECRYPTION_PATH = "/CryptHTTPS/Decrypt.asp"
        DELIMITER = '*P1*'

        CURRENCY_MAPPING = {
          'EUR' => '242',
          'ITL' => '18',
          'BRL' => '234',
          'USD' => '1',
          'JPY' => '71',
          'HKD' => '103'
        }



        def parse_response(response)
          case response
          when /#cryptstring#(.*)#\/cryptstring#/, /#decryptstring#(.*)#\/decryptstring#/
            $1
          when /#error#(.*)#\/error#/
            raise GestpayEncryptionResponseError, "An error occurred retrieving the encrypted string from GestPay: #{$1}"
          else
            raise GestpayEncryptionResponseError, "No response was received by GestPay"
          end
        end

        def ssl_get(url, path)
          uri = URI.parse(url)
          site = Net::HTTP.new(uri.host, uri.port)
          site.use_ssl = true
          site.verify_mode    = OpenSSL::SSL::VERIFY_NONE
          site.get(path).body
        end
      end

      class Helper < OffsitePayments::Helper
        include Common
        # Valid language codes
        #   Italian   => 1
        #   English   => 2
        #   Spanish   => 3
        #   French    => 4
        #   Tedesco   => 5
        def initialize(order, account, options = {})
          super
          add_field('PAY1_IDLANGUAGE', 2)
        end

        mapping :account, 'ShopLogin'

        mapping :amount, 'PAY1_AMOUNT'
        mapping :currency, 'PAY1_UICCODE'

        mapping :order, 'PAY1_SHOPTRANSACTIONID'

        # Buyer name PAY1_CHNAME
        mapping :customer, :email => 'PAY1_CHEMAIL'

        mapping :credit_card, :number       => 'PAY1_CARDNUMBER',
                              :expiry_month => 'PAY1_EXPMONTH',
                              :expiry_year  => 'PAY1_EXPYEAR',
                              :verification_value => 'PAY1_CVV'

        def customer(params = {})
          add_field(mappings[:customer][:email], params[:email])
          add_field('PAY1_CHNAME', "#{params[:first_name]} #{params[:last_name]}")
        end

        def currency=(currency_code)
          code = CURRENCY_MAPPING[currency_code]
          raise ActionViewHelperError, "Invalid currency code #{currency_code} specified" if code.nil?

          add_field(mappings[:currency], code)
        end

        def form_fields
          @encrypted_data ||= get_encrypted_string

          {
            'a' => @fields['ShopLogin'],
            'b' => @encrypted_data
          }
        end

        def get_encrypted_string
          response = ssl_get(Gestpay.service_url, encryption_query_string)
          parse_response(response)
        rescue GestpayEncryptionResponseError => e
          raise ActionViewHelperError.new(e)
        end

        def encryption_query_string
          fields = ['PAY1_AMOUNT', 'PAY1_SHOPTRANSACTIONID', 'PAY1_UICCODE']

          encoded_params = fields.collect{ |field| "#{field}=#{CGI.escape(@fields[field])}" }.join(DELIMITER)

          "#{ENCRYPTION_PATH}?a=" + CGI.escape(@fields['ShopLogin']) + "&b=" + encoded_params + "&c=" + CGI.escape(VERSION)
        end
      end

      class Notification < OffsitePayments::Notification
        include Common

        def complete?
          status == 'Completed'
        end

        # The important param
        def item_id
          params['PAY1_SHOPTRANSACTIONID']
        end

        def transaction_id
          params['PAY1_BANKTRANSACTIONID']
        end

        # the money amount we received in X.2 decimal.
        def gross
          params['PAY1_AMOUNT']
        end

        def currency
          # Ruby 1.9 compat
          method = CURRENCY_MAPPING.respond_to?(:key) ? :key : :index
          CURRENCY_MAPPING.send(method, params['PAY1_UICCODE'])
        end

        def test?
          false
        end

        def status
          case params['PAY1_TRANSACTIONRESULT']
          when 'OK'
            'Completed'
          else
            'Failed'
          end
        end

        def acknowledge(authcode = nil)
          true
        end

        private
        # Take the posted data and move the relevant data into a hash
        def parse(query_string)
          @raw = query_string

          return if query_string.blank?
          encrypted_params = parse_delimited_string(query_string)

          return if encrypted_params['a'].blank? || encrypted_params['b'].blank?
          @params = decrypt_data(encrypted_params['a'], encrypted_params['b'])
        end

        def parse_delimited_string(string, delimiter = '&', unencode_cgi = false)
          result = {}
          for line in string.split(delimiter)
            key, value = *line.scan( %r{^(\w+)\=(.*)$} ).flatten
            result[key] = unencode_cgi ? CGI.unescape(value) : value
          end
          result
        end

        def decrypt_data(shop_login, encrypted_string)
          response = ssl_get(Gestpay.service_url, decryption_query_string(shop_login, encrypted_string))
          encoded_response = parse_response(response)
          parse_delimited_string(encoded_response, DELIMITER, true)
        end

        def decryption_query_string(shop_login, encrypted_string)
          "#{DECRYPTION_PATH}?a=" + CGI.escape(shop_login) + "&b=" + encrypted_string + "&c=" + CGI.escape(VERSION)
        end
      end

      class Return < OffsitePayments::Return
      end
    end
  end
end
