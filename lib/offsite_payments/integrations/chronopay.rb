module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module Chronopay
      mattr_accessor :service_url
      self.service_url = 'https://secure.chronopay.com/index_shop.cgi'

      def self.notification(post, options = {})
        Notification.new(post)
      end

      def self.return(query_string, options = {})
        Return.new(query_string)
      end

      class Helper < OffsitePayments::Helper
        # All currently supported checkout languages:
        #   es (Spanish)
        #   en (English)
        #   de (German)
        #   pt (Portuguese)
        #   lv (Latvian)
        #   cn1 (Chinese Version 1)
        #   cn2 (Chinese version 2)
        #   nl (Dutch)
        #   ru (Russian)
        COUNTRIES_FOR_LANG = {
          'ES'  => %w( AR BO CL CO CR CU DO EC SV GQ GT HN MX NI PA PY PE ES UY VE),
          'DE'  => %w( DE AT CH LI ),
          'PT'  => %w( AO BR CV GW MZ PT ST TL),
          'RU'  => %w( BY KG KZ RU ),
          'LV'  => %w( LV ),
          'CN1' => %w( CN ),
          'NL'  => %w( NL )
        }

        LANG_FOR_COUNTRY = COUNTRIES_FOR_LANG.inject(Hash.new("EN")) do |memo, (lang, countries)|
          countries.each do |code|
            memo[code] = lang
          end
          memo
        end


        self.country_format = :alpha3

        def initialize(order, account, options = {})
          super
          add_field('cb_type', 'p')
        end

        # product_id
        mapping :account, 'product_id'
        # product_name
        mapping :invoice, 'product_name'
        # product_price
        mapping :amount,   'product_price'
        # product_price_currency
        mapping :currency, 'product_price_currency'

        # f_name
        # s_name
        # email
        mapping :customer, :first_name => 'f_name',
                           :last_name  => 's_name',
                           :phone      => 'phone',
                           :email      => 'email'

        # city
        # street
        # state
        # zip
        # country - The country must be a 3 digit country code
        # phone

        mapping :billing_address, :city     => 'city',
                                  :address1 => 'street',
                                  :state    => 'state',
                                  :zip      => 'zip',
                                  :country  => 'country'

        def billing_address(mapping = {})
          # Gets the country code in the appropriate format or returns what we were given
          # The appropriate format for Chronopay is the alpha 3 country code
          country_code = lookup_country_code(mapping.delete(:country))
          add_field(mappings[:billing_address][:country], country_code)

          countries_with_supported_states = ['USA', 'CAN']
          if !countries_with_supported_states.include?(country_code)
            mapping.delete(:state)
            add_field(mappings[:billing_address][:state], 'XX')
          end
          mapping.each do |k, v|
            field = mappings[:billing_address][k]
            add_field(field, v) unless field.nil?
          end
          add_field('language', checkout_language_from_country(country_code))
        end

        # card_no
        # exp_month
        # exp_year
        mapping :credit_card, :number       => 'card_no',
                              :expiry_month => 'exp_month',
                              :expiry_year  => 'exp_year'

        # cb_url
        mapping :notify_url, 'cb_url'

        # cs1
        mapping :order, 'cs1'

        # cs2
        # cs3
        # decline_url


        private

        def checkout_language_from_country(country_code)
          country    = ActiveMerchant::Country.find(country_code)
          short_code = country.code(:alpha2).to_s
          LANG_FOR_COUNTRY[short_code]
        rescue ActiveMerchant::InvalidCountryCodeError
          'EN'
        end
      end

      class Notification < OffsitePayments::Notification
        def complete?
          status == 'Completed'
        end

        # Status of transaction. List of possible values:
        # <tt>onetime – one time payment has been made, no repayment required;</tt>::
        # <tt>initial – first payment has been made, repayment required in corresponding period;</tt>::
        # <tt>decline – charge request has been rejected;</tt>::
        # <tt>rebill – repayment has been made together with initial transaction;</ttt>::
        # <tt>cancel – repayments has been disabled;</tt>::
        # <tt>expire – customer’s access to restricted zone membership has been expired;</tt>::
        # <tt>refund – request to refund has been received;</tt>::
        # <tt>chargeback – request to chargeback has been received.</tt>::
        #
        # This implementation of Chronopay does not support subscriptions.
        # The status codes used are matched to the status codes that Paypal
        # sends.  See Paypal::Notification#status for more details
        def status
          case params['transaction_type']
          when 'onetime'
            'Completed'
          when 'refund'
            'Refunded'
          when 'chargeback'
            'Reversed'
          else
            'Failed'
          end
        end

        # Unique ID of transaction
        def transaction_id
          params['transaction_id']
        end

        # Unique ID of customer
        def customer_id
          params['customer_id']
        end

        # Unique ID of Merchant’s web-site
        def site_id
          params['site_id']
        end

        # ID of a product that was purchased
        def product_id
          params['product_id']
        end

        # Language
        def language
          params['language']
        end

        def received_at
          # Date should be formatted "dd-mm-yy" to be parsed by 1.8 and 1.9 the same way
          formatted_date = Date.strptime(date, "%m/%d/%Y").strftime("%d-%m-%Y")
          Time.parse("#{formatted_date} #{time}") unless date.blank? || time.blank?
        end

        # Date of transaction in MM/DD/YYYY format
        def date
          params['date']
        end

        # Time of transaction in HH:MM:SS format
        def time
          params['time']
        end

        # The customer's full name
        def name
          params['name']
        end

        # The customer's email address
        def email
          params['email']
        end

        # The customer's street address
        def street
          params['street']
        end

        # The customer's country - 3 digit country code
        def country
          params['country']
        end

        # The customer's city
        def city
          params['city']
        end

        # The customer's zip
        def zip
          params['zip']
        end

        # The customer's state.  Only useful for US Customers
        def state
          params['state']
        end

        # Customer’s login for restricted access zone of Merchant’s Web-site
        def username
          params['username']
        end

        # Customer's password for restricted access zone of Merchant’s Web-site, as chosen
        def password
          params['password']
        end

        # The item id passed in the first custom parameter
        def item_id
          params['cs1']
        end

        # Additional parameter
        def custom2
          params['cs2']
        end

        # Additional parameter
        def custom3
          params['cs3']
        end

        # The currency the purchase was made in
        def currency
          params['currency']
        end

        # the money amount we received in X.2 decimal.
        def gross
          params['total']
        end

        def test?
          date.blank? && time.blank? && transaction_id.blank?
        end

        def acknowledge(authcode = nil)
          true
        end
      end

      class Return < OffsitePayments::Return
      end
    end
  end
end
