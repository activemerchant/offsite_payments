module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module RealexOffsite
      mattr_accessor :production_url
      mattr_accessor :test_url
      self.production_url = 'https://epage.payandshop.com/epage.cgi'
      self.test_url       = 'https://hpp.sandbox.realexpayments.com/pay'

      def self.helper(order, account, options={})
        Helper.new(order, account, options)
      end

      def self.notification(query_string, options={})
        Notification.new(query_string, options)
      end

      def self.return(query_string, options={})
        Return.new(query_string, options)
      end

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

      module Common
        CURRENCY_SPECIAL_MINOR_UNITS = {
          'BIF' => 0,
          'BYR' => 0,
          'CLF' => 0,
          'CLP' => 0,
          'CVE' => 0,
          'DJF' => 0,
          'GNF' => 0,
          'HUF' => 0,
          'ISK' => 0,
          'JPY' => 0,
          'KMF' => 0,
          'KRW' => 0,
          'PYG' => 0,
          'RWF' => 0,
          'UGX' => 0,
          'UYI' => 0,
          'VND' => 0,
          'VUV' => 0,
          'XAF' => 0,
          'XOF' => 0,
          'XPF' => 0,
          'BHD' => 3,
          'IQD' => 3,
          'JOD' => 3,
          'KWD' => 3,
          'LYD' => 3,
          'OMR' => 3,
          'TND' => 3,
          'COU' => 4
        }

        CANADIAN_STATES = {
          'AB' => 'Alberta',
          'BC' => 'British Columbia',
          'MB' => 'Manitoba',
          'NB' => 'New Brunswick',
          'NL' => 'Newfoundland',
          'NS' => 'Nova Scotia',
          'NU' => 'Nunavut',
          'NT' => 'Northwest Territories',
          'ON' => 'Ontario',
          'PE' => 'Prince Edward Island',
          'QC' => 'Quebec',
          'SK' => 'Saskatchewan',
          'YT' => 'Yukon'
        }

        US_STATES = {
          'AL' => 'Alabama',
          'AK' => 'Alaska',
          'AS' => 'American Samoa',
          'AZ' => 'Arizona',
          'AR' => 'Arkansas',
          'CA' => 'California',
          'CO' => 'Colorado',
          'CT' => 'Connecticut',
          'DE' => 'Delaware',
          'DC' => 'District Of Columbia',
          'FM' => 'Federated States Of Micronesia',
          'FL' => 'Florida',
          'GA' => 'Georgia',
          'GU' => 'Guam',
          'HI' => 'Hawaii',
          'ID' => 'Idaho',
          'IL' => 'Illinois',
          'IN' => 'Indiana',
          'IA' => 'Iowa',
          'KS' => 'Kansas',
          'KY' => 'Kentucky',
          'LA' => 'Louisiana',
          'ME' => 'Maine',
          'MH' => 'Marshall Islands',
          'MD' => 'Maryland',
          'MA' => 'Massachusetts',
          'MI' => 'Michigan',
          'MN' => 'Minnesota',
          'MS' => 'Mississippi',
          'MO' => 'Missouri',
          'MT' => 'Montana',
          'NE' => 'Nebraska',
          'NV' => 'Nevada',
          'NH' => 'New Hampshire',
          'NJ' => 'New Jersey',
          'NM' => 'New Mexico',
          'NY' => 'New York',
          'NC' => 'North Carolina',
          'ND' => 'North Dakota',
          'MP' => 'Northern Mariana Islands',
          'OH' => 'Ohio',
          'OK' => 'Oklahoma',
          'OR' => 'Oregon',
          'PW' => 'Palau',
          'PA' => 'Pennsylvania',
          'PR' => 'Puerto Rico',
          'RI' => 'Rhode Island',
          'SC' => 'South Carolina',
          'SD' => 'South Dakota',
          'TN' => 'Tennessee',
          'TX' => 'Texas',
          'UT' => 'Utah',
          'VT' => 'Vermont',
          'VI' => 'Virgin Islands',
          'VA' => 'Virginia',
          'WA' => 'Washington',
          'WV' => 'West Virginia',
          'WI' => 'Wisconsin',
          'WY' => 'Wyoming'
        }


        def create_signature(fields, secret)
          data = fields.join('.')
          digest = Digest::SHA1.hexdigest(data)
          signed = "#{digest}.#{secret}"
          Digest::SHA1.hexdigest(signed)
        end

        # Realex accepts currency amounts as an integer in the lowest value
        # e.g.
        #     format_amount(110.56, 'GBP')
        #     => 11056
        def format_amount(amount, currency)
          units = CURRENCY_SPECIAL_MINOR_UNITS[currency] || 2
          multiple = 10**units
          return ((amount || 0).to_d * multiple.to_d).to_i
        end

        # Realex returns currency amount as an integer
        def format_amount_as_float(amount, currency)
          units = CURRENCY_SPECIAL_MINOR_UNITS[currency] || 2
          divisor = 10**units
          return ((amount || 0).to_d / divisor.to_d)
        end

        def extract_digits(value)
          return unless value
          value.scan(/\d+/).join('')
        end

        def extract_avs_code(params={})
          [extract_digits(params[:zip]), extract_digits(params[:address1])].join('|')
        end

        def extract_address_match_indicator(value)
          value ? 'TRUE' : 'FALSE'
        end

        # The home phone number provided by the Cardholder. Should be In format:
        # of 'CountryCallingCode|Number' for example, '1|123456789'.
        def format_phone_number(phone_number)
          return nil if phone_number.nil?

          clean_number = phone_number.gsub(/\D/, '')

          return phone_number if clean_number.length < 10

          country_code = clean_number[0, clean_number.length - 9]
          number = clean_number[clean_number.length - 9, clean_number.length]

          "#{country_code}|#{number}"
        end

        def lookup_state_code(country_code, state)
          case country_code
          when 'CA'
            state_code = CANADIAN_STATES.find { |code, state_name| state_name.downcase == state.downcase}
            state_code ? state_code.first : state
          when 'US'
            state_code = US_STATES.find { |code, state_name| state_name.downcase == state.downcase}
            state_code ? state_code.first : state
          end
        end

        # if HPP_ADDRESS_MATCH_INDICATOR is set to TRUE
        # HPP requires the shipping address to be sent from the billing address
        def copy_billing_address
          @fields.select { |k, _| k.start_with? 'HPP_BILLING_' }
                 .each do |k, v|
                   add_field("HPP_SHIPPING_#{k.split('HPP_BILLING_')[1]}", v)
                 end
        end
      end

      class Helper < OffsitePayments::Helper
        include Common

        self.country_format = :numeric

        def initialize(order, account, options = {})
          @timestamp   = Time.now.strftime('%Y%m%d%H%M%S')
          @currency    = options[:currency]
          @merchant_id = account
          @sub_account = options[:credential2]
          @secret      = options[:credential3]
          super
          # Credentials
          add_field 'MERCHANT_ID', @merchant_id
          add_field 'ACCOUNT', @sub_account
          # Defaults
          add_field 'AUTO_SETTLE_FLAG', '1'
          add_field 'RETURN_TSS', '1'
          add_field 'TIMESTAMP', @timestamp
          add_field 'HPP_VERSION', '2'
          # Realex does not send back CURRENCY param in response
          # however it does echo any other param so we send it twice.
          add_field 'X-CURRENCY', @currency
          add_field 'X-TEST', @test.to_s
          add_field 'ORDER_ID', "#{order}#{@timestamp.to_i}"
          add_field 'COMMENT1', application_id
        end

        def form_fields
          sign_fields
        end

        def amount=(amount)
          add_field 'AMOUNT', format_amount(amount, @currency)
        end

        def billing_address(params={})
          country = params[:country]
          country_code = lookup_country_code(country, :alpha2)
          super

          add_field(mappings[:billing_address][:zip], extract_avs_code(params))
          add_field(mappings[:billing_address][:country], lookup_country_code(country))

          if ['US', 'CA'].include?(country_code) && params[:state].length > 2
            add_field(mappings[:billing_address][:state], lookup_state_code(country_code, params[:state]))
          end
        end

        def shipping_address(params={})
          country = params[:country]
          country_code = lookup_country_code(country, :alpha2)
          super

          add_field(mappings[:shipping_address][:zip], extract_avs_code(params))
          add_field(mappings[:shipping_address][:country], lookup_country_code(params[:country]))

          if ['US', 'CA'].include?(country_code) && params[:state].length > 2
            add_field(mappings[:shipping_address][:state], lookup_state_code(country_code, params[:state]))
          end
        end

        def customer(params={})
          super
          add_field(mappings[:customer][:phone], format_phone_number(params[:phone]))
        end

        def addresses_match(address_match = nil)
          return if address_match.nil?

          add_field(
            mappings[:addresses_match],
            extract_address_match_indicator(address_match)
          )

          copy_billing_address if address_match
        end

        def comment(comment = nil)
          add_field(mappings[:comment], comment)
        end

        # HPP does not want shipping address and HPP_ADDRESS_MATCH_INDICATOR to be sent
        # if the product does not require shipping
        def require_shipping(require_shipping = nil)
          return unless require_shipping == false

          @fields.delete_if do |k, _|
            k.start_with?('HPP_SHIPPING_') || k == 'HPP_ADDRESS_MATCH_INDICATOR'
          end
        end

        def sign_fields
          @fields.merge!('SHA1HASH' => generate_signature)
        end

        def generate_signature
          fields_to_sign = []
          ['TIMESTAMP', 'MERCHANT_ID', 'ORDER_ID', 'AMOUNT', 'CURRENCY'].each do |field|
            fields_to_sign << @fields[field]
          end

          create_signature(fields_to_sign, @secret)
        end

        # Realex Required Fields
        mapping :currency,         'CURRENCY'

        mapping :order,            'CHECKOUT_ID'
        mapping :amount,           'AMOUNT'
        mapping :notify_url,       'MERCHANT_RESPONSE_URL'
        mapping :return_url,       'MERCHANT_RETURN_URL'


        # Realex Optional fields
        mapping :customer,        :email => 'HPP_CUSTOMER_EMAIL',
                                  :phone => 'HPP_CUSTOMER_PHONENUMBER_MOBILE'

        mapping :shipping_address, :zip =>        'HPP_SHIPPING_POSTALCODE',
                                   :country =>    'HPP_SHIPPING_COUNTRY',
                                   :address1 =>   'HPP_SHIPPING_STREET1',
                                   :address2 =>   'HPP_SHIPPING_STREET2',
                                   :address3 =>   'HPP_SHIPPING_STREET3',
                                   :city =>       'HPP_SHIPPING_CITY',
                                   :state =>      'HPP_SHIPPING_STATE'

        mapping :billing_address,  :zip =>        'HPP_BILLING_POSTALCODE',
                                   :country =>    'HPP_BILLING_COUNTRY',
                                   :address1 =>   'HPP_BILLING_STREET1',
                                   :address2 =>   'HPP_BILLING_STREET2',
                                   :address3 =>   'HPP_BILLING_STREET3',
                                   :city =>       'HPP_BILLING_CITY',
                                   :state =>      'HPP_BILLING_STATE'

        mapping :addresses_match,  'HPP_ADDRESS_MATCH_INDICATOR'
        mapping :comment, 'COMMENT2'
      end

      class Notification < OffsitePayments::Notification
        include Common
        def initialize(post, options={})
          super
          @secret = options[:credential3]
        end

        # Required Notification methods to define
        def acknowledge(authcode = nil)
          verified?
        end

        def item_id
          checkout_id
        end

        def transaction_id
          pasref
        end

        def test?
          params['X-TEST']
        end

        def status
          if result == '00'
            'Completed'
          else
            'Invalid'
          end
        end

        # Realex does not send back the currency param by default
        # we have sent this additional parameter
        def currency
          params['X-CURRENCY']
        end

        def gross
          format_amount_as_float(params['AMOUNT'], currency)
        end

        def complete?
          verified? && status == 'Completed'
        end

        # Fields for Realex signature verification
        def timestamp
          params['TIMESTAMP']
        end

        def merchant_id
          params['MERCHANT_ID']
        end

        def checkout_id
          params['CHECKOUT_ID']
        end

        def order_id
          params['ORDER_ID']
        end

        def result
          params['RESULT']
        end

        def message
          params['MESSAGE']
        end

        def authcode
          params['AUTHCODE']
        end

        def signature
          params['SHA1HASH']
        end

        def calculated_signature
          fields = [timestamp, merchant_id, order_id, result, message, pasref, authcode]
          create_signature(fields, @secret)
        end

        def verified?
          signature == calculated_signature
        end

        # Extra data (available from Realex)
        def cvn_result
          params['CVNRESULT']
        end

        def avs_postcode_result
          params['AVSPOSTCODERESULT']
        end

        def avs_address_result
          params['AVSADDRESSRESULT']
        end

        def pasref
          params['PASREF']
        end

        def eci
          params['ECI']
        end

        def cavv
          params['CAVV']
        end

        def xid
          params['XID']
        end

      end

      class Return < OffsitePayments::Return
        def initialize(data, options)
          super
          @notification = Notification.new(data, options)
        end

        def success?
          notification.complete?
        end

        # TODO: realex does not provide a separate cancelled endpoint
        def cancelled?
          false
        end

        def message
          notification.message
        end
      end

    end
  end
end
