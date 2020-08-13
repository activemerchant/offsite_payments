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

        COUNTRY_PHONE_NUMBERS = {
          'AD' => { :code => '376', :length => [6, 7, 8, 9] },
          'AE' => { :code => '971', :length => [7, 8, 9] },
          'AF' => { :code => '93', :length => [8, 9] },
          'AG' => { :code => '1', :length => [10] },
          'AI' => { :code => '1', :length => [10] },
          'AL' => { :code => '355', :length => [7, 8, 9] },
          'AM' => { :code => '374', :length => [8] },
          'AO' => { :code => '244', :length => [9] },
          'AQ' => { :code => '672', :length => [] },
          'AR' => { :code => '54', :length => [8, 9] },
          'AS' => { :code => '1', :length => [10] },
          'AT' => { :code => '43', :length => [7, 8, 9, 10, 11, 12, 13] },
          'AU' => { :code => '61', :length => [9] },
          'AW' => { :code => '297', :length => [7] },
          'AX' => { :code => '358', :length => [] },
          'AZ' => { :code => '994', :length => [8, 9] },
          'BA' => { :code => '387', :length => [8] },
          'BB' => { :code => '1', :length => [10] },
          'BD' => { :code => '880', :length => [10] },
          'BE' => { :code => '32', :length => [8, 9] },
          'BF' => { :code => '226', :length => [8] },
          'BG' => { :code => '359', :length => [8, 9, 10] },
          'BH' => { :code => '973', :length => [8] },
          'BI' => { :code => '257', :length => [8] },
          'BJ' => { :code => '229', :length => [8] },
          'BL' => { :code => '590', :length => [] },
          'BM' => { :code => '1', :length => [10] },
          'BN' => { :code => '673', :length => [7] },
          'BO' => { :code => '591', :length => [8] },
          'BQ' => { :code => '599', :length => [7] },
          'BR' => { :code => '55', :length => [10, 11] },
          'BS' => { :code => '1', :length => [10] },
          'BT' => { :code => '975', :length => [7, 8] },
          'BV' => { :code => '47', :length => [] },
          'BW' => { :code => '267', :length => [7] },
          'BY' => { :code => '375', :length => [9] },
          'BZ' => { :code => '501', :length => [7] },
          'CA' => { :code => '1', :length => [10] },
          'CC' => { :code => '61', :length => [9] },
          'CD' => { :code => '243', :length => [8] },
          'CF' => { :code => '236', :length => [8] },
          'CG' => { :code => '242', :length => [7] },
          'CH' => { :code => '41', :length => [9, 10] },
          'CI' => { :code => '225', :length => [8] },
          'CK' => { :code => '682', :length => [5] },
          'CL' => { :code => '56', :length => [8, 9] },
          'CM' => { :code => '237', :length => [8] },
          'CN' => { :code => '86', :length => [7, 8, 9, 10, 11] },
          'CO' => { :code => '57', :length => [9, 10] },
          'CR' => { :code => '506', :length => [8] },
          'CU' => { :code => '53', :length => [8] },
          'CV' => { :code => '238', :length => [7] },
          'CW' => { :code => '599', :length => [7] },
          'CX' => { :code => '61', :length => [] },
          'CY' => { :code => '357', :length => [8] },
          'CZ' => { :code => '420', :length => [9] },
          'DE' => { :code => '49', :length => [6, 7, 8, 9, 10, 11] },
          'DJ' => { :code => '253', :length => [6] },
          'DK' => { :code => '45', :length => [8] },
          'DM' => { :code => '1', :length => [10] },
          'DO' => { :code => '1', :length => [10] },
          'DZ' => { :code => '213', :length => [8] },
          'EC' => { :code => '593', :length => [8, 9] },
          'EE' => { :code => '372', :length => [7, 8] },
          'EG' => { :code => '20', :length => [9] },
          'EH' => { :code => '212', :length => [] },
          'ER' => { :code => '291', :length => [7] },
          'ES' => { :code => '34', :length => [9] },
          'ET' => { :code => '251', :length => [9] },
          'FI' => { :code => '358', :length => [9] },
          'FJ' => { :code => '679', :length => [7] },
          'FK' => { :code => '500', :length => [5] },
          'FM' => { :code => '691', :length => [7] },
          'FO' => { :code => '298', :length => [6] },
          'FR' => { :code => '33', :length => [9, 10] },
          'GA' => { :code => '241', :length => [6, 7, 8] },
          'GB' => { :code => '44', :length => [10, 11] },
          'GD' => { :code => '1', :length => [10] },
          'GE' => { :code => '995', :length => [9] },
          'GF' => { :code => '594', :length => [10] },
          'GG' => { :code => '44', :length => [] },
          'GH' => { :code => '233', :length => [5, 6, 7, 8] },
          'GI' => { :code => '350', :length => [8] },
          'GL' => { :code => '299', :length => [6] },
          'GM' => { :code => '220', :length => [7] },
          'GN' => { :code => '224', :length => [8] },
          'GP' => { :code => '590', :length => [10] },
          'GQ' => { :code => '240', :length => [6] },
          'GR' => { :code => '30', :length => [10] },
          'GS' => { :code => '500', :length => [] },
          'GT' => { :code => '502', :length => [8] },
          'GU' => { :code => '1', :length => [10] },
          'GW' => { :code => '245', :length => [7] },
          'GY' => { :code => '592', :length => [6, 7] },
          'HK' => { :code => '852', :length => [8] },
          'HN' => { :code => '504', :length => [7, 8] },
          'HR' => { :code => '385', :length => [8] },
          'HT' => { :code => '509', :length => [8] },
          'HU' => { :code => '36', :length => [8, 9] },
          'ID' => { :code => '62', :length => [8, 9, 10, 11] },
          'IE' => { :code => '353', :length => [9] },
          'IL' => { :code => '972', :length => [7, 8, 9] },
          'IM' => { :code => '44', :length => [] },
          'IN' => { :code => '91', :length => [10] },
          'IO' => { :code => '246', :length => [] },
          'IQ' => { :code => '964', :length => [8, 9, 10] },
          'IR' => { :code => '98', :length => [10] },
          'IS' => { :code => '354', :length => [7, 8, 9] },
          'IT' => { :code => '39', :length => [9, 11] },
          'JE' => { :code => '44', :length => [] },
          'JM' => { :code => '1', :length => [10] },
          'JO' => { :code => '962', :length => [8, 9] },
          'JP' => { :code => '81', :length => [9, 10] },
          'KE' => { :code => '254', :length => [9] },
          'KG' => { :code => '996', :length => [9] },
          'KH' => { :code => '855', :length => [8] },
          'KI' => { :code => '686', :length => [5] },
          'KM' => { :code => '269', :length => [7] },
          'KN' => { :code => '1', :length => [10] },
          'KP' => { :code => '850', :length => [8, 9] },
          'KR' => { :code => '82', :length => [8, 9] },
          'KW' => { :code => '965', :length => [7] },
          'KY' => { :code => '1', :length => [10] },
          'KZ' => { :code => '7', :length => [10] },
          'LA' => { :code => '856', :length => [8] },
          'LB' => { :code => '961', :length => [8] },
          'LC' => { :code => '1', :length => [10] },
          'LI' => { :code => '423', :length => [7] },
          'LK' => { :code => '94', :length => [10] },
          'LR' => { :code => '231', :length => [6, 7, 8] },
          'LS' => { :code => '266', :length => [8] },
          'LT' => { :code => '370', :length => [8] },
          'LU' => { :code => '352', :length => [9] },
          'LV' => { :code => '371', :length => [8] },
          'LY' => { :code => '218', :length => [8, 9] },
          'MA' => { :code => '212', :length => [8] },
          'MC' => { :code => '377', :length => [8, 9] },
          'MD' => { :code => '373', :length => [8] },
          'ME' => { :code => '382', :length => [8] },
          'MF' => { :code => '590', :length => [] },
          'MG' => { :code => '261', :length => [9] },
          'MH' => { :code => '692', :length => [7] },
          'MK' => { :code => '389', :length => [7, 8] },
          'ML' => { :code => '223', :length => [8] },
          'MM' => { :code => '95', :length => [7, 8] },
          'MN' => { :code => '976', :length => [7, 8, 9, 10] },
          'MO' => { :code => '853', :length => [8] },
          'MP' => { :code => '1', :length => [10] },
          'MQ' => { :code => '596', :length => [10] },
          'MR' => { :code => '222', :length => [7] },
          'MS' => { :code => '1', :length => [10] },
          'MT' => { :code => '356', :length => [8] },
          'MU' => { :code => '230', :length => [7] },
          'MV' => { :code => '960', :length => [7] },
          'MW' => { :code => '265', :length => [8] },
          'MX' => { :code => '52', :length => [8, 9, 10] },
          'MY' => { :code => '60', :length => [9, 10] },
          'MZ' => { :code => '258', :length => [8, 9] },
          'NA' => { :code => '264', :length => [6, 7] },
          'NC' => { :code => '687', :length => [6] },
          'NE' => { :code => '227', :length => [8] },
          'NF' => { :code => '672', :length => [6] },
          'NG' => { :code => '234', :length => [7, 8] },
          'NI' => { :code => '505', :length => [8] },
          'NL' => { :code => '31', :length => [9] },
          'NO' => { :code => '47', :length => [8] },
          'NP' => { :code => '977', :length => [7, 8] },
          'NR' => { :code => '674', :length => [7] },
          'NU' => { :code => '683', :length => [4] },
          'NZ' => { :code => '64', :length => [8, 9] },
          'OM' => { :code => '968', :length => [8] },
          'PA' => { :code => '507', :length => [7] },
          'PE' => { :code => '51', :length => [8, 9] },
          'PF' => { :code => '689', :length => [6] },
          'PG' => { :code => '675', :length => [7] },
          'PH' => { :code => '63', :length => [8, 9, 10] },
          'PK' => { :code => '92', :length => [9, 10] },
          'PL' => { :code => '48', :length => [9] },
          'PM' => { :code => '508', :length => [6] },
          'PN' => { :code => '64', :length => [9] },
          'PR' => { :code => '1', :length => [10] },
          'PS' => { :code => '970', :length => [8] },
          'PT' => { :code => '351', :length => [9] },
          'PW' => { :code => '680', :length => [7] },
          'PY' => { :code => '595', :length => [9] },
          'QA' => { :code => '974', :length => [7] },
          'RE' => { :code => '262', :length => [10] },
          'RO' => { :code => '40', :length => [9] },
          'RS' => { :code => '381', :length => [9] },
          'RU' => { :code => '7', :length => [10] },
          'RW' => { :code => '250', :length => [8, 9] },
          'SA' => { :code => '966', :length => [8, 9] },
          'SB' => { :code => '677', :length => [5] },
          'SC' => { :code => '248', :length => [6] },
          'SD' => { :code => '249', :length => [9] },
          'SE' => { :code => '46', :length => [9] },
          'SG' => { :code => '65', :length => [8, 9] },
          'SH' => { :code => '290', :length => [4] },
          'SI' => { :code => '386', :length => [8] },
          'SJ' => { :code => '47', :length => [8] },
          'SK' => { :code => '421', :length => [9] },
          'SL' => { :code => '232', :length => [8] },
          'SM' => { :code => '378', :length => [9, 10, 11, 12] },
          'SN' => { :code => '221', :length => [7] },
          'SO' => { :code => '252', :length => [7, 8] },
          'SR' => { :code => '597', :length => [6] },
          'SS' => { :code => '211', :length => [9] },
          'ST' => { :code => '239', :length => [6, 7] },
          'SV' => { :code => '503', :length => [8] },
          'SX' => { :code => '1', :length => [10] },
          'SY' => { :code => '963', :length => [7, 8] },
          'SZ' => { :code => '268', :length => [7] },
          'TC' => { :code => '1', :length => [10] },
          'TD' => { :code => '235', :length => [7] },
          'TF' => { :code => '262', :length => [] },
          'TG' => { :code => '228', :length => [7] },
          'TH' => { :code => '66', :length => [9, 10] },
          'TJ' => { :code => '992', :length => [9] },
          'TK' => { :code => '690', :length => [4] },
          'TL' => { :code => '670', :length => [7] },
          'TM' => { :code => '993', :length => [8] },
          'TN' => { :code => '216', :length => [8] },
          'TO' => { :code => '676', :length => [5, 6, 7] },
          'TR' => { :code => '90', :length => [10] },
          'TT' => { :code => '1', :length => [10] },
          'TV' => { :code => '688', :length => [5] },
          'TW' => { :code => '886', :length => [7, 8] },
          'TZ' => { :code => '255', :length => [9] },
          'UA' => { :code => '380', :length => [8, 9] },
          'UG' => { :code => '256', :length => [9] },
          'UM' => { :code => '1', :length => [] },
          'US' => { :code => '1', :length => [10] },
          'UY' => { :code => '598', :length => [7, 8] },
          'UZ' => { :code => '998', :length => [9] },
          'VA' => { :code => '39', :length => [9] },
          'VC' => { :code => '1', :length => [10] },
          'VE' => { :code => '58', :length => [10] },
          'VG' => { :code => '1', :length => [10] },
          'VI' => { :code => '1', :length => [10] },
          'VN' => { :code => '84', :length => [7, 8, 9, 10] },
          'VU' => { :code => '678', :length => [5, 6, 7] },
          'WF' => { :code => '681', :length => [6] },
          'WS' => { :code => '685', :length => [6, 7] },
          'YE' => { :code => '967', :length => [7, 8, 9] },
          'YT' => { :code => '262', :length => [7] },
          'ZA' => { :code => '27', :length => [9] },
          'ZM' => { :code => '260', :length => [9] },
          'ZW' => { :code => '263', :length => [8, 9, 10, 11] }       
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

          country_number = COUNTRY_PHONE_NUMBERS[country_code] || { :code => '0', :length => [] }

          # Remove non-digit characters
          processed_number = phone_number.gsub(/\D/, '')
          return '0|0' if [[], ['0']].include? processed_number.chars.uniq

          # Allow Italy and Ivory Coast to have leading zero, as they use it as a part of some phone numbers
          if ['IT', 'CI'].include?(country_code) && /\A0[1-9]\d*/.match(processed_number)
            return "#{country_number[:code]}|#{processed_number}"[0...19]
          end

          return '0|0' if processed_number == country_number[:code]
          
          # Remove leading zero(s)
          processed_number = processed_number.gsub(/\A0*/, '')

          # Check if the potential Singapore calling code is not the local prefix
          if country_code == 'SG' &&
            processed_number.start_with?(country_number[:code]) &&
            country_number[:length].include?(processed_number.length)
          then
            return "#{country_number[:code]}|#{processed_number}"[0...19]
          end

          # Remove country calling code from the processed number and try to fix trivial mistakes
          if processed_number.start_with?(country_number[:code]) ||
            (!(country_number[:length].include?(processed_number.length)) &&
            country_number[:length].include?(processed_number.length - country_number[:code].length) &&
            (country_number[:code].chars.sort == processed_number[0...country_number[:code].length].chars.sort))
          then
            processed_number = processed_number[country_number[:code].length..-1]
          end

          # Limit returned string to 19 characters
          "#{country_number[:code]}|#{processed_number}"[0...19]
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

          if @fields[mappings[:customer][:phone]]
            add_field(mappings[:customer][:phone], format_phone_number(@phone_number, country_code))
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

          if @fields[mappings[:customer][:phone]]&.[](0..1) == '0|'
            add_field(mappings[:customer][:phone], format_phone_number(@phone_number, country_code))
          end
        end

        def customer(params={})
          super

          country = @fields[mappings[:billing_address][:country]]
          @phone_number = params[:phone]
        
          add_field(mappings[:customer][:phone], format_phone_number(@phone_number, lookup_country_code(country, :alpha2)))
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
