module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module SagePayForm
      mattr_accessor :production_url
      mattr_accessor :test_url
      mattr_accessor :simulate_url
      self.production_url = 'https://live.sagepay.com/gateway/service/vspform-register.vsp'
      self.test_url       = 'https://test.sagepay.com/gateway/service/vspform-register.vsp'
      self.simulate_url   = 'https://test.sagepay.com/Simulator/VSPFormGateway.asp'

      def self.return(query_string, options = {})
        Return.new(query_string, options)
      end

      def self.service_url
        mode = OffsitePayments.mode
        case mode
        when :production
          self.production_url
        when :test
          self.test_url
        when :simulate
          self.simulate_url
        else
          raise StandardError, "Integration mode set to an invalid value: #{mode}"
        end
      end

      module Encryption
        def sage_encrypt(plaintext, key)
          encrypted = cipher(:encrypt, key, plaintext)
          "@#{encrypted.upcase}"
        end

        def sage_decrypt(ciphertext, key)
          ciphertext = ciphertext[1..-1] # remove @ symbol at the beginning of a string
          cipher(:decrypt, key, ciphertext)
        rescue OpenSSL::Cipher::CipherError => e
          return '' if e.message == 'wrong final block length'
          raise
        end

        def sage_encrypt_salt(min, max)
          length = rand(max - min + 1) + min
          SecureRandom.base64(length + 4)[0, length]
        end

        private

        def cipher(action, key, payload)
          if action == :decrypt
            payload = [payload].pack('H*')
          end

          cipher = OpenSSL::Cipher::AES128.new(:CBC)
          cipher.public_send(action)
          cipher.key = key
          cipher.iv = key
          result = cipher.update(payload) + cipher.final

          if action == :encrypt
            result = result.unpack('H*')[0]
          end

          result
        end
      end

      class Helper < OffsitePayments::Helper
        include Encryption

        attr_reader :identifier

        def initialize(order, account, options={})
          super
          @identifier = rand(0..99999).to_s.rjust(5, '0')
          add_field 'VendorTxCode', "#{order}-#{@identifier}"
        end

        mapping :credential2, 'EncryptKey'

        mapping :account, 'Vendor'
        mapping :amount, 'Amount'
        mapping :currency, 'Currency'

        mapping :customer,
          :first_name => 'BillingFirstnames',
          :last_name  => 'BillingSurname',
          :email      => 'CustomerEMail',
          :phone      => 'BillingPhone',
          :send_email_confirmation => 'SendEmail'

        mapping :billing_address,
          :city     => 'BillingCity',
          :address1 => 'BillingAddress1',
          :address2 => 'BillingAddress2',
          :state    => 'BillingState',
          :zip      => 'BillingPostCode',
          :country  => 'BillingCountry'

        mapping :shipping_address,
          :city     => 'DeliveryCity',
          :address1 => 'DeliveryAddress1',
          :address2 => 'DeliveryAddress2',
          :state    => 'DeliveryState',
          :zip      => 'DeliveryPostCode',
          :country  => 'DeliveryCountry'

        mapping :return_url, 'SuccessURL'
        mapping :description, 'Description'

        class_attribute :referrer_id

        def shipping_address(params = {})
          @shipping_address_set = true unless params.empty?

          params.each do |k, v|
            field = mappings[:shipping_address][k]
            add_field(field, v) unless field.nil?
          end
        end

        def map_billing_address_to_shipping_address
          %w(City Address1 Address2 State PostCode Country).each do |field|
            fields["Delivery#{field}"] = fields["Billing#{field}"]
          end
        end

        def form_fields
          fields.delete('locale')

          map_billing_address_to_shipping_address unless @shipping_address_set

          fields['DeliveryFirstnames'] ||= fields['BillingFirstnames']
          fields['DeliverySurname']    ||= fields['BillingSurname']

          fields['FailureURL'] ||= fields['SuccessURL']

          fields['BillingPostCode'] ||= "0000"
          fields['DeliveryPostCode'] ||= "0000"

          fields['ReferrerID'] = referrer_id if referrer_id

          crypt_skip = ['Vendor', 'EncryptKey', 'SendEmail']
          crypt_skip << 'BillingState'  unless fields['BillingCountry']  == 'US'
          crypt_skip << 'DeliveryState' unless fields['DeliveryCountry'] == 'US'
          crypt_skip << 'CustomerEMail' unless fields['SendEmail']
          key = fields['EncryptKey']
          @crypt ||= create_crypt_field(fields.except(*crypt_skip), key)

          {
            'VPSProtocol' => '3.00',
            'TxType' => 'PAYMENT',
            'Vendor' => @fields['Vendor'],
            'Crypt'  => @crypt
          }
        end

        private

        def create_crypt_field(fields, key)
          parts = fields.map { |k, v| "#{k}=#{sanitize(k, v)}" unless v.nil? }.compact.shuffle
          parts.unshift(sage_encrypt_salt(key.length, key.length * 2))
          sage_encrypt(parts.join('&'), key)
        rescue OpenSSL::Cipher::CipherError, ArgumentError => e
          if e.message == 'key length too short' || e.message == 'key must be 16 bytes'
            raise ActionViewHelperError, 'Invalid encryption key.'
          else
            raise
          end
        end

        def sanitize(key, value)
          reject = exact = nil

          case key
          when /URL$/
            # allow all
          when 'VendorTxCode'
            reject = /[^A-Za-z0-9{}._-]+/
          when /[Nn]ames?$/
            reject = %r{[^[:alpha:] /\\.'-]+}
          when /(?:Address[12]|City)$/
            reject = %r{[^[:alnum:] +'/\\:,.\n()-]+}
          when /PostCode$/
            reject = /[^A-Za-z0-9 -]+/
          when /Phone$/
            reject = /[^0-9A-Za-z+ ()-]+/
          when 'Currency'
            exact = /^[A-Z]{3}$/
          when /State$/
            exact = /^[A-Z]{2}$/
          when 'Description'
            value = value[0...100]
          else
            reject = /&+/
          end

          if exact
            raise ArgumentError, "Invalid value for #{key}: #{value.inspect}" unless value =~ exact
            value
          elsif reject
            value.gsub(reject, ' ')
          else
            value
          end
        end
      end

      class Notification < OffsitePayments::Notification
        class CryptError < StandardError; end

        include Encryption

        def initialize(post_data, options)
          super
          load_crypt_params(params['crypt'], options[:credential2])
        end

        # Was the transaction complete?
        def complete?
          status_code == 'OK'
        end

        # Was the transaction cancelled?
        # Unfortunately, we can't distinguish "user abort" from "idle too long".
        def cancelled?
          status_code == 'ABORT'
        end

        # Text version of #complete?, since we don't support Pending.
        def status
          complete? ? 'Completed' : 'Failed'
        end

        # Status of transaction. List of possible values:
        # <tt>OK</tt>:: Transaction completed successfully.
        # <tt>NOTAUTHED</tt>:: Incorrect card details / insufficient funds.
        # <tt>MALFORMED</tt>:: Invalid input data.
        # <tt>INVALID</tt>:: Valid input data, but some fields are incorrect.
        # <tt>ABORT</tt>:: User hit cancel button or went idle for 15+ minutes.
        # <tt>REJECTED</tt>:: Rejected by account fraud screening rules.
        # <tt>AUTHENTICATED</tt>:: Authenticated card details secured at SagePay.
        # <tt>REGISTERED</tt>:: Non-authenticated card details secured at SagePay.
        # <tt>ERROR</tt>:: Problem internal to SagePay.
        def status_code
          params['Status']
        end

        # Check this if #completed? is false.
        def message
          params['StatusDetail']
        end

        # Vendor-supplied code (:order mapping).
        def item_id
          params['VendorTxCode'].rpartition('-').first
        end

        # Internal SagePay code, typically "{LONG-UUID}".
        def transaction_id
          params['VPSTxId']
        end

        # Authorization number (only if #completed?).
        def auth_id
          params['TxAuthNo']
        end

        # Total amount (no fees).
        def gross
          params['Amount'].gsub(/,(?=\d{3}\b)/, '')
        end

        # AVS and CV2 check results.  Possible values:
        # <tt>ALL MATCH</tt>::
        # <tt>SECURITY CODE MATCH ONLY</tt>::
        # <tt>ADDRESS MATCH ONLY</tt>::
        # <tt>NO DATA MATCHES</tt>::
        # <tt>DATA NOT CHECKED</tt>::
        def avs_cv2_result
          params['AVSCV2']
        end

        # Numeric address check.  Possible values:
        # <tt>NOTPROVIDED</tt>::
        # <tt>NOTCHECKED</tt>::
        # <tt>MATCHED</tt>::
        # <tt>NOTMATCHED</tt>::
        def address_result
          params['AddressResult']
        end

        # Post code check.  Possible values:
        # <tt>NOTPROVIDED</tt>::
        # <tt>NOTCHECKED</tt>::
        # <tt>MATCHED</tt>::
        # <tt>NOTMATCHED</tt>::
        def post_code_result
          params['PostCodeResult']
        end

        # CV2 code check.  Possible values:
        # <tt>NOTPROVIDED</tt>::
        # <tt>NOTCHECKED</tt>::
        # <tt>MATCHED</tt>::
        # <tt>NOTMATCHED</tt>::
        def cv2_result
          params['CV2Result']
        end

        # Was the Gift Aid box checked?
        def gift_aid?
          params['GiftAid'] == '1'
        end

        # Result of 3D Secure checks.  Possible values:
        # <tt>OK</tt>:: Authenticated correctly.
        # <tt>NOTCHECKED</tt>:: Authentication not performed.
        # <tt>NOTAVAILABLE</tt>:: Card not auth-capable, or auth is otherwise impossible.
        # <tt>NOTAUTHED</tt>:: User failed authentication.
        # <tt>INCOMPLETE</tt>:: Authentication unable to complete.
        # <tt>ERROR</tt>:: Unable to attempt authentication due to data / service errors.
        def buyer_auth_result
          params['3DSecureStatus']
        end

        # Encoded 3D Secure result code.
        def buyer_auth_result_code
          params['CAVV']
        end

        # Address confirmation status.  PayPal only.  Possible values:
        # <tt>NONE</tt>::
        # <tt>CONFIRMED</tt>::
        # <tt>UNCONFIRMED</tt>::
        def address_status
          params['AddressStatus']
        end

        # Payer verification.  Undocumented.
        def payer_verified?
          params['PayerStatus'] == 'VERIFIED'
        end

        # Credit card type.  Possible values:
        # <tt>VISA</tt>:: Visa
        # <tt>MC</tt>:: MasterCard
        # <tt>DELTA</tt>:: Delta
        # <tt>SOLO</tt>:: Solo
        # <tt>MAESTRO</tt>:: Maestro (UK and International)
        # <tt>UKE</tt>:: Visa Electron
        # <tt>AMEX</tt>:: American Express
        # <tt>DC</tt>:: Diners Club
        # <tt>JCB</tt>:: JCB
        # <tt>LASER</tt>:: Laser
        # <tt>PAYPAL</tt>:: PayPal
        def credit_card_type
          params['CardType']
        end

        # Last four digits of credit card.
        def credit_card_last_4_digits
          params['Last4Digits']
        end

        # Used by composition methods, but not supplied by SagePay.
        def currency
          nil
        end

        def test?
          false
        end

        def acknowledge
          true
        end

        private

        def load_crypt_params(crypt, key)
          raise MissingCryptData if crypt.blank?
          raise MissingCryptKey  if key.blank?

          crypt_data = sage_decrypt(crypt.gsub(' ', '+'), key)
          raise InvalidCryptData unless crypt_data =~ /(^|&)Status=/

          params.clear
          parse(crypt_data)
        end

        class MissingCryptKey  < CryptError
          def message
            'No merchant decryption key supplied'
          end
        end
        class MissingCryptData < CryptError
          def message
            'No data received from SagePay'
          end
        end
        class InvalidCryptData < CryptError
          def message
            'Invalid data received from SagePay'
          end
        end
      end

      class Return < OffsitePayments::Return
        def initialize(query_string, options)
          begin
            @notification = Notification.new(query_string, options)
          rescue Notification::CryptError => e
            @message = e.message
          end
        end

        def success?
          @notification && @notification.complete?
        end

        def cancelled?
          @notification && @notification.cancelled?
        end

        def message
          @message || @notification.message
        end
      end
    end
  end
end
