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

        COUNTRY_CALLING_CODES = {
          'AD' => '376',
          'AE' => '971',
          'AF' => '93',
          'AG' => '1',
          'AI' => '1',
          'AL' => '355',
          'AM' => '374',
          'AO' => '244',
          'AQ' => '672',
          'AR' => '54',
          'AS' => '1',
          'AT' => '43',
          'AU' => '61',
          'AW' => '297',
          'AX' => '358',
          'AZ' => '994',
          'BA' => '387',
          'BB' => '1',
          'BD' => '880',
          'BE' => '32',
          'BF' => '226',
          'BG' => '359',
          'BH' => '973',
          'BI' => '257',
          'BJ' => '229',
          'BL' => '590',
          'BM' => '1',
          'BN' => '673',
          'BO' => '591',
          'BQ' => '599',
          'BR' => '55',
          'BS' => '1',
          'BT' => '975',
          'BV' => '47',
          'BW' => '267',
          'BY' => '375',
          'BZ' => '501',
          'CA' => '1',
          'CC' => '61',
          'CD' => '243',
          'CF' => '236',
          'CG' => '242',
          'CH' => '41',
          'CI' => '225',
          'CK' => '682',
          'CL' => '56',
          'CM' => '237',
          'CN' => '86',
          'CO' => '57',
          'CR' => '506',
          'CU' => '53',
          'CV' => '238',
          'CW' => '599',
          'CX' => '61',
          'CY' => '357',
          'CZ' => '420',
          'DE' => '49',
          'DJ' => '253',
          'DK' => '45',
          'DM' => '1',
          'DO' => '1',
          'DZ' => '213',
          'EC' => '593',
          'EE' => '372',
          'EG' => '20',
          'EH' => '212',
          'ER' => '291',
          'ES' => '34',
          'ET' => '251',
          'FI' => '358',
          'FJ' => '679',
          'FK' => '500',
          'FM' => '691',
          'FO' => '298',
          'FR' => '33',
          'GA' => '241',
          'GB' => '44',
          'GD' => '1',
          'GE' => '995',
          'GF' => '594',
          'GG' => '44',
          'GH' => '233',
          'GI' => '350',
          'GL' => '299',
          'GM' => '220',
          'GN' => '224',
          'GP' => '590',
          'GQ' => '240',
          'GR' => '30',
          'GS' => '500',
          'GT' => '502',
          'GU' => '1',
          'GW' => '245',
          'GY' => '592',
          'HK' => '852',
          'HM' => '',
          'HN' => '504',
          'HR' => '385',
          'HT' => '509',
          'HU' => '36',
          'ID' => '62',
          'IE' => '353',
          'IL' => '972',
          'IM' => '44',
          'IN' => '91',
          'IO' => '246',
          'IQ' => '964',
          'IR' => '98',
          'IS' => '354',
          'IT' => '39',
          'JE' => '44',
          'JM' => '1',
          'JO' => '962',
          'JP' => '81',
          'KE' => '254',
          'KG' => '996',
          'KH' => '855',
          'KI' => '686',
          'KM' => '269',
          'KN' => '1',
          'KP' => '850',
          'KR' => '82',
          'KW' => '965',
          'KY' => '1',
          'KZ' => '7',
          'LA' => '856',
          'LB' => '961',
          'LC' => '1',
          'LI' => '423',
          'LK' => '94',
          'LR' => '231',
          'LS' => '266',
          'LT' => '370',
          'LU' => '352',
          'LV' => '371',
          'LY' => '218',
          'MA' => '212',
          'MC' => '377',
          'MD' => '373',
          'ME' => '382',
          'MF' => '590',
          'MG' => '261',
          'MH' => '692',
          'MK' => '389',
          'ML' => '223',
          'MM' => '95',
          'MN' => '976',
          'MO' => '853',
          'MP' => '1',
          'MQ' => '596',
          'MR' => '222',
          'MS' => '1',
          'MT' => '356',
          'MU' => '230',
          'MV' => '960',
          'MW' => '265',
          'MX' => '52',
          'MY' => '60',
          'MZ' => '258',
          'NA' => '264',
          'NC' => '687',
          'NE' => '227',
          'NF' => '672',
          'NG' => '234',
          'NI' => '505',
          'NL' => '31',
          'NO' => '47',
          'NP' => '977',
          'NR' => '674',
          'NU' => '683',
          'NZ' => '64',
          'OM' => '968',
          'PA' => '507',
          'PE' => '51',
          'PF' => '689',
          'PG' => '675',
          'PH' => '63',
          'PK' => '92',
          'PL' => '48',
          'PM' => '508',
          'PN' => '64',
          'PR' => '1',
          'PS' => '970',
          'PT' => '351',
          'PW' => '680',
          'PY' => '595',
          'QA' => '974',
          'RE' => '262',
          'RO' => '40',
          'RS' => '381',
          'RU' => '7',
          'RW' => '250',
          'SA' => '966',
          'SB' => '677',
          'SC' => '248',
          'SD' => '249',
          'SE' => '46',
          'SG' => '65',
          'SH' => '290',
          'SI' => '386',
          'SJ' => '47',
          'SK' => '421',
          'SL' => '232',
          'SM' => '378',
          'SN' => '221',
          'SO' => '252',
          'SR' => '597',
          'SS' => '211',
          'ST' => '239',
          'SV' => '503',
          'SX' => '1',
          'SY' => '963',
          'SZ' => '268',
          'TC' => '1',
          'TD' => '235',
          'TF' => '262',
          'TG' => '228',
          'TH' => '66',
          'TJ' => '992',
          'TK' => '690',
          'TL' => '670',
          'TM' => '993',
          'TN' => '216',
          'TO' => '676',
          'TR' => '90',
          'TT' => '1',
          'TV' => '688',
          'TW' => '886',
          'TZ' => '255',
          'UA' => '380',
          'UG' => '256',
          'UM' => '1',
          'US' => '1',
          'UY' => '598',
          'UZ' => '998',
          'VA' => '39',
          'VC' => '1',
          'VE' => '58',
          'VG' => '1',
          'VI' => '1',
          'VN' => '84',
          'VU' => '678',
          'WF' => '681',
          'WS' => '685',
          'YE' => '967',
          'YT' => '262',
          'ZA' => '27',
          'ZM' => '260',
          'ZW' => '263'
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
        def format_phone_number(phone_number, country_code)
          return nil if phone_number.nil?

          # Remove non-digit characters
          processed_number = phone_number.gsub(/\D/, '')

          # Remove leading zero(s)
          processed_number = processed_number.gsub(/\A0*/, '')

          # Remove country calling code from the processed number
          country_calling_code = COUNTRY_CALLING_CODES[country_code] || ''

          if processed_number.start_with?(country_calling_code)
            processed_number = processed_number[country_calling_code.length..-1]
          end

          number = "#{country_calling_code}|#{processed_number}"

          return nil if number.length > 19

          number
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

          if @fields[mappings[:customer][:phone]]&.chr == '|'
            phone = @fields[mappings[:customer][:phone]].split('|').last

            add_field(mappings[:customer][:phone], format_phone_number(phone, country_code))
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

          if @fields[mappings[:customer][:phone]]
            phone = @fields[mappings[:customer][:phone]].split('|').last

            add_field(mappings[:customer][:phone], format_phone_number(phone, country_code))
          end
        end

        def customer(params={})
          super
          country = @fields[mappings[:shipping_address][:country]]
          add_field(mappings[:customer][:phone], format_phone_number(params[:phone], lookup_country_code(country, :alpha2)))
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
