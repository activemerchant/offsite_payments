module OffsitePayments
  module Integrations
    module Migs
      API_VERSION = 1

      def self.return(query_string, options = {})
        Return.new(query_string, options)
      end

      class Helper < OffsitePayments::Helper
        def self.base_url
          'https://migs.mastercard.com.au/vpcpay'
        end

        def initialize(order, account, options = {})
          @credentials = { login: account, password: options.fetch(:password) }
          @secure_hash = options.fetch(:secure_hash)
          @options = options.merge(order_id: order)
        end

        # Generates a URL to redirect user to MiGS to process payment
        # Once user is finished MiGS will redirect back to specified URL
        # With a response hash which can be turned into a Response object
        # with purchase_offsite_response
        #
        # ==== Options
        #
        # * <tt>:order_id</tt> -- A reference for tracking the order (REQUIRED)
        # * <tt>:locale</tt> -- Change the language of the redirected page
        #   Values are 2 digit locale, e.g. en, es
        # * <tt>:return_url</tt> -- the URL to return to once the payment is complete
        # * <tt>:card_type</tt> -- Providing this skips the card type step.
        #   Values are ActiveMerchant formats: e.g. master, visa, american_express, diners_club
        # * <tt>:unique_id</tt> -- Unique id of transaction to find.
        #   If not supplied one will be generated.
        def credential_based_url
          cents = @options.fetch(:cents)
          builder = TransactionBuilder.new(@credentials)
          builder.add_invoice(@options)
          builder.add_creditcard_type(@options[:card_type]) if @options[:card_type]
          builder.add_amount(cents)
          builder.add_standard_parameters('pay', @options[:unique_id])
          post = builder.post.merge(
            Locale: @options[:locale] || 'en',
            ReturnURL: @options.fetch(:return_url)
          )
          post[:SecureHash] = SecureHash.calculate(@secure_hash, post)

          self.class.base_url + '?' + post_data(post)
        end

        private

        def post_data(post)
          post.collect { |key, value| "vpc_#{key}=#{CGI.escape(value.to_s)}" }.join("&")
        end
      end

      class Notification < OffsitePayments::Notification
        def initialize(params, options = {})
          @params = params
          @response = parse
          @options = options
        end

        def parse
          @params.map.with_object({}) { |(key, value), hash|
            hash[key.gsub('vpc_', '').to_sym] = value
          }
        end

        def avs_response_code
          avs_response_code = @response[:AVSResultCode]
          avs_response_code = 'S' if avs_response_code == "Unsupported"
          avs_response_code
        end

        def cvv_result_code
          cvv_result_code = @response[:CSCResultCode]
          cvv_result_code = 'P' if cvv_result_code == "Unsupported"
          cvv_result_code
        end

        def success?
          @response[:TxnResponseCode] == '0'
        end

        def fraud_review?
          ISSUER_RESPONSE_CODES[@response[:AcqResponseCode]] == 'Suspected Fraud'
        end

        def acknowledge
          # Failures don't include a secure hash, so return directly
          return true unless success?

          # Check SecureHash only on success (not returned otherwise)
          unless @response[:SecureHash] == expected_secure_hash
            raise SecurityError, "Secure Hash mismatch, response may be tampered with"
          end

          true
        end

        def expected_secure_hash
          SecureHash.calculate(@options[:secure_hash], @response)
        end

        def gross
          @response[:Amount].to_d / 100.0
        end

        def card_code
          return unless @response.key?(:Card) # Card doesn't appear on failure
          migs_code = @response[:Card]
          CARD_TYPES.detect { |ct|
            ct.migs_code == migs_code
          }.am_code
        end

        def order_id
          @response[:OrderInfo]
        end

        def uid
          @response[:MerchTxnRef]
        end

        def transaction_id
          @response[:TransactionNo]
        end

        def message # only when error
          @response['Message']
        end
      end

      def test?
        # TEST prefix defines if login is for test system, see page 37 of:
        # https://anz.com.au/australia/business/merchant/pdf/MIGSProductGuide.pdf
        @options[:login].start_with?('TEST')
      end

      class SecureHash
        require 'digest/md5' # Used in add_secure_hash

        def self.calculate(secure_hash, post)
          post_without_secure_hash = post.reject { |k, _v| k == :SecureHash }
          sorted_values = post_without_secure_hash.sort_by(&:to_s).map(&:last)
          input = secure_hash + sorted_values.join
          Digest::MD5.hexdigest(input).upcase
        end
      end

      private

      class CreditCardType
        attr_accessor :am_code, :migs_code, :migs_long_code, :name
        def initialize(am_code, migs_code, migs_long_code, name)
          @am_code        = am_code
          @migs_code      = migs_code
          @migs_long_code = migs_long_code
          @name           = name
        end
      end

      CARD_TYPES = [
        # The following are 4 different representations of credit card types
        # am_code: The active merchant code
        # migs_code: Used in response for purchase/authorize/status
        # migs_long_code: Used to pre-select card for server_purchase_url
        # name: The nice display name
        %w(american_express AE Amex             American\ Express),
        %w(diners_club      DC Dinersclub       Diners\ Club),
        %w(jcb              JC JCB              JCB\ Card),
        %w(maestro          MS Maestro          Maestro\ Card),
        %w(master           MC Mastercard       MasterCard),
        %w(na               PL PrivateLabelCard Private\ Label\ Card),
        %w(visa             VC Visa             Visa\ Card')
      ].map { |am_code, migs_code, migs_long_code, name|
        CreditCardType.new(am_code, migs_code, migs_long_code, name)
      }

      class TransactionBuilder
        attr_reader :post

        def initialize(options)
          @options = options
          @post = {}
        end

        def add_invoice(options)
          post[:OrderInfo] = options.fetch(:order_id)
        end

        def add_amount(cents)
          post[:Amount] = cents.to_s
        end

        def add_creditcard(creditcard)
          post[:CardNum] = creditcard.number
          post[:CardSecurityCode] = creditcard.verification_value if creditcard.verification_value?
          post[:CardExp] = format(creditcard.year) + format(creditcard.month)
        end

        def add_creditcard_type(card_type)
          post[:Gateway] = 'ssl'
          post[:card] = CARD_TYPES.detect{|ct| ct.am_code == card_type}.migs_long_code
        end

        def add_advanced_user
          post[:User] = @options[:advanced_login]
          post[:Password] = @options[:advanced_password]
        end

        def add_standard_parameters(action, unique_id = nil)
          post.merge!(
            :Version     => API_VERSION,
            :Merchant    => @options[:login],
            :AccessCode  => @options[:password],
            :Command     => action,
            :MerchTxnRef => unique_id || SecureRandom.hex(16).slice(0, 40)
          )
        end

        private

        def format(number)
          sprintf("%.2i", number.to_i)[-2..-1]
        end
      end
    end
  end
end
