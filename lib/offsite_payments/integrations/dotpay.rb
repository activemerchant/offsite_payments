module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module Dotpay
      mattr_accessor :service_url
      self.service_url = 'https://ssl.dotpay.pl'

      def self.notification(post, options = {})
        Notification.new(post, options)
      end

      def self.return(post, options = {})
        Return.new(post, options)
      end

      class Helper < OffsitePayments::Helper
        def initialize(order, account, options = {})
          options = {:currency => 'PLN'}.merge options

          super

          add_field('channel', '0')
          add_field('ch_lock', '0')
          add_field('lang', 'PL')
          add_field('onlinetransfer', '0')
          add_field('tax', '0')
          add_field('type', '2')
        end

        mapping :account,         'id'
        mapping :amount,          'amount'

        mapping :billing_address, :street => 'street',
                                  :street_n1 => 'street_n1',
                                  :street_n2 => 'street_n2',
                                  :addr2 => 'addr2',
                                  :addr3 => 'addr3',
                                  :city => 'city',
                                  :postcode => 'postcode',
                                  :phone => 'phone',
                                  :country => 'country'

        mapping :buttontext,      'buttontext'
        mapping :channel,         'channel'
        mapping :ch_lock,         'ch_lock'
        mapping :code,            'code'
        mapping :control,         'control'
        mapping :currency,        'currency'

        mapping :customer,        :firstname => 'firstname',
                                  :lastname => 'lastname',
                                  :email => 'email'

        mapping :description,     'description'
        mapping :lang,            'lang'
        mapping :onlinetransfer,  'onlinetransfer'
        mapping :order,           'description'
        mapping :p_email,         'p_email'
        mapping :p_info,          'p_info'
        mapping :tax,             'tax'
        mapping :type,            'type'
        mapping :url,             'url'
        mapping :urlc,            'urlc'

        def billing_address(params = {})
          country = lookup_country_code(params.delete(:country) { 'POL' }, :alpha3)
          add_field(mappings[:billing_address][:country], country)

          # Everything else
          params.each do |k, v|
            field = mappings[:billing_address][k]
            add_field(field, v) unless field.nil?
          end
        end

        private

        def lookup_country_code(name_or_code, format = country_format)
          country = ActiveMerchant::Country.find(name_or_code)
          country.code(format).to_s
        rescue ActiveMerchant::InvalidCountryCodeError
          name_or_code
        end
      end

      class Notification < OffsitePayments::Notification
        def complete?
          status == 'OK' && %w(2 4 5).include?(t_status)
        end

        def currency
          orginal_amount.split(' ')[1]
        end

        # the money amount we received in X.2 decimal.
        def gross
          params['amount']
        end

        def pin=(value)
          @options[:pin] = value
        end

        def status
          params['status']
        end

        def test?
          params['t_id'].match('.*-TST\d+') ? true : false
        end

        PAYMENT_HOOK_FIELDS = [
          :id,
          :control,
          :t_id,
          :orginal_amount,
          :email,
          :service,
          :code,
          :username,
          :password,
          :t_status,
          :description,
          :md5,
          :p_info,
          :p_email,
          :t_date
        ]

        PAYMENT_HOOK_SIGNATURE_FIELDS = [
          :id,
          :control,
          :t_id,
          :amount,
          :email,
          :service,
          :code,
          :username,
          :password,
          :t_status
        ]

        # Provide access to raw fields
        PAYMENT_HOOK_FIELDS.each do |key|
          define_method(key.to_s) do
             params[key.to_s]
          end
        end

        def generate_signature_string
          "#{@options[:pin]}:" + PAYMENT_HOOK_SIGNATURE_FIELDS.map {|key| params[key.to_s]} * ":"
        end

        def generate_signature
          Digest::MD5.hexdigest(generate_signature_string)
        end

        def acknowledge(authcode = nil)
          generate_signature.to_s == md5.to_s
        end
      end

      class Return < OffsitePayments::Return
      end
    end
  end
end
