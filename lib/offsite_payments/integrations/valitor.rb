module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module Valitor
      mattr_accessor :test_url
      self.test_url = 'https://paymentweb.uat.valitor.is/'

      mattr_accessor :production_url
      self.production_url = 'https://paymentweb.valitor.is/'

      def self.test?
        (OffsitePayments.mode == :test)
      end

      def self.service_url
        (test? ? test_url : production_url)
      end

      def self.notification(params, options={})
        Notification.new(params, options.merge(:test => test?))
      end

      def self.return(query_string, options={})
        Return.new(query_string, options.merge(:test => test?))
      end

      class Helper < OffsitePayments::Helper
        include ActiveUtils::RequiresParameters

        DEFAULT_SUCCESS_TEXT = "The transaction has been completed."

        def initialize(order, account, options={})
          options[:currency] ||= 'ISK'
          super
          add_field 'AuthorizationOnly', '0'
          add_field 'DisplayBuyerInfo', '0'

          add_field 'Language', 'IS'

          @security_number = options[:credential2]
          @amount          = options[:amount]
          @order           = order
        end

        mapping :account, 'MerchantID'
        mapping :currency, 'Currency'

        mapping :order, 'ReferenceNumber'

        mapping :notify_url, 'PaymentSuccessfulServerSideURL'
        mapping :return_url, 'PaymentSuccessfulURL'
        mapping :cancel_return_url, 'PaymentCancelledURL'

        mapping :session_expired_timeout_in_seconds, 'SessionExpiredTimeoutInSeconds'
        mapping :session_expired_redirect_url, 'SessionExpiredRedirectURL'
        mapping :card_loan_user_name, 'MerchantName'

        mapping :success_text, 'PaymentSuccessfulURLText'

        mapping :language, 'Language'

        def language=(val)
          raise ArgumentError, "Language can only be one of IS, EN, DA or DE" unless %w(IS EN DA DE).include?(val)
          add_field 'Language', val
        end

        def authorize_only
          add_field 'AuthorizationOnly', '1'
        end

        def collect_customer_info
          add_field 'DisplayBuyerInfo', '1'
        end

        def payment_successful_automatic_redirect
          add_field 'PaymentSuccessfulAutomaticRedirect', '1'
        end

        def is_card_loan
          add_field 'IsCardLoan', '1'
        end

        def card_loan_is_interest_free
          add_field 'IsInterestFree', '1'
        end

        def require_postal_code
          add_field 'RequirePostalCode', '1'
        end

        def hide_postal_code
          add_field 'HidePostalCode', '1'
        end

        %w(SSN Name Address City Country Phone Email Comments).each do |name|
          define_method :"require_#{name.downcase}" do
            add_field "Require#{name}", '1'
          end

          define_method :"hide_#{name.downcase}" do
            add_field "Hide#{name}", '1'
          end
        end


        def product(id, options={})
          raise ArgumentError, "Product id #{id} is not an integer between 1 and 500" unless id.to_i > 0 && id.to_i <= 500
          requires!(options, :amount, :description)
          options.assert_valid_keys([:description, :quantity, :amount, :discount])

          add_field("Product_#{id}_Price", options[:amount])
          add_field("Product_#{id}_Quantity", options[:quantity] || "1")

          add_field("Product_#{id}_Description", options[:description]) if options[:description]
          add_field("Product_#{id}_Discount", options[:discount] || '0')

          @products ||= []
          @products << id.to_i
        end

        def signature
          raise ArgumentError, "Security number not set" unless @security_number
          parts = [@security_number, @fields['AuthorizationOnly']]
          @products.sort.uniq.each do |id|
            parts.concat(["Product_#{id}_Quantity", "Product_#{id}_Price", "Product_#{id}_Discount"].collect{|e| @fields[e]})
          end if @products
          parts.concat(%w(MerchantID ReferenceNumber PaymentSuccessfulURL PaymentSuccessfulServerSideURL Currency).collect{|e| @fields[e]})
          Digest::MD5.hexdigest(parts.compact.join(''))
        end

        def form_fields
          product(1, :amount => @amount, :description => @order) if Array(@products).empty?

          @products.each do |id|
            @fields["Product_#{id}_Price"] = format_amount(@fields["Product_#{id}_Price"], @fields[mappings[:currency]])
          end

          @fields[mappings[:success_text]] ||= DEFAULT_SUCCESS_TEXT
          @fields.merge('DigitalSignature' => signature)
        end

        def format_amount(amount, currency)
          OffsitePayments::CURRENCIES_WITHOUT_FRACTIONS.include?(currency) ? amount.to_f.round : sprintf("%.2f", amount).sub('.', ',')
        end
      end

      module ResponseFields
        def success?
          status == 'Completed'
        end
        alias :complete? :success?

        def test?
          @options[:test]
        end

        def item_id
          params['ReferenceNumber']
        end
        alias :order :item_id

        def transaction_id
          params['SaleID']
        end

        def currency
          nil
        end

        def status
          "Completed" if acknowledge
        end

        def received_at
          Time.parse(params['Date'].to_s)
        end

        def gross
          return "0" if !params['Upphaed']
          "%0.2f" % params['Upphaed'].to_s.sub(',', '.')
        end

        def card_type
          params['CardType']
        end

        def card_last_four
          params['CardNumberMasked'][-4..]
        end

        def authorization_number
          params['AuthorizationNumber']
        end

        def transaction_number
          params['TransactionNumber']
        end

        def customer_name
          params['Name']
        end

        def customer_address
          params['Address']
        end

        def customer_zip
          params['PostalCode']
        end

        def customer_city
          params['City']
        end

        def customer_country
          params['Country']
        end

        def customer_email
          params['Email']
        end

        def customer_comment
          params['Comments']
        end

        def password
          @options[:credential2]
        end

        def acknowledge(authcode = nil)
          password ? Digest::MD5.hexdigest("#{password}#{order}") == params['DigitalSignatureResponse'] : true
        end
      end

      class Notification < OffsitePayments::Notification
        include ResponseFields
      end

      class Return < OffsitePayments::Return
        include ResponseFields
      end
    end
  end
end
