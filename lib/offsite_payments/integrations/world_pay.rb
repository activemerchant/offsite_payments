require 'ipaddr'
module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module WorldPay
      mattr_accessor :production_url, :test_url
      self.production_url = 'https://secure.worldpay.com/wcc/purchase'
      self.test_url = 'https://secure-test.worldpay.com/wcc/purchase'

      def self.service_url
        case OffsitePayments.mode
        when :production
          self.production_url
        when :test
          self.test_url
        else
          raise StandardError, "Integration mode set to an invalid value: #{mode}"
        end
      end

      def self.notification(post, options = {})
        Notification.new(post, options)
      end

      def self.return(post, options = {})
        Return.new(post, options)
      end

      class Helper < OffsitePayments::Helper
        mapping :account, 'instId'
        mapping :amount, 'amount'
        mapping :order, 'cartId'
        mapping :currency, 'currency'

        mapping :customer, :email => 'email',
                           :phone => 'tel'

        mapping :billing_address,
          :address1 => 'address1',
          :address2 => 'address2',
          :city => 'town',
          :state => 'region',
          :zip => 'postcode',
          :country  => 'country'

        mapping :description, 'desc'
        mapping :notify_url, 'MC_callback'
        mapping :return_url, 'MC_return'

        # WorldPay supports two different test modes - :always_succeed and :always_fail
        def initialize(order, account, options = {})
          super

          if OffsitePayments.mode == :test || options[:test]
            test_mode = case options[:test]
            when :always_fail
              101
            when false
              0
            else
              100
            end
            add_field('testMode', test_mode.to_s)
          elsif OffsitePayments.mode == :always_succeed
            add_field('testMode', '100')
          elsif OffsitePayments.mode == :always_fail
            add_field('testMode', '101')
          end
        end

        # WorldPay only supports a single name field so we have to concat
        def customer(params={})
          add_field(mappings[:customer][:email], params[:email])
          add_field(mappings[:customer][:phone], params[:phone])
          add_field('name', "#{params[:first_name]} #{params[:last_name]}")
        end

        # Support for a MD5 hash of selected fields to prevent tampering
        # For further information read the tech note at the address below:
        # http://support.worldpay.com/kb/integration_guides/junior/integration/help/tech_notes/sjig_tn_009.html
        def encrypt(secret, fields = [:amount, :currency, :account, :order])
          signature_fields = fields.collect{ |field| mappings[field] }
          add_field('signatureFields', signature_fields.join(':'))

          field_values = fields.collect{ |field| form_fields[mappings[field]] }
          signature    = "#{secret}:#{field_values.join(':')}"
          add_field('signature', Digest::MD5.hexdigest(signature))
        end

        # Add a time window for which the payment can be completed. Read the link below for how they work
        # http://support.worldpay.com/kb/integration_guides/junior/integration/help/appendicies/sjig_10100.html
        def valid_from(from_time)
          add_field('authValidFrom', from_time.to_i.to_s + '000')
        end

        def valid_to(to_time)
          add_field('authValidTo', to_time.to_i.to_s + '000')
        end

        # WorldPay supports the passing of custom parameters prefixed with the following:
        # C_          : These parameters can be used in the response pages hosted on WorldPay's site
        # M_          : These parameters are passed through to the callback script (if enabled)
        # MC_ or CM_  : These parameters are availble both in the response and callback contexts
        def response_params(params={})
          params.each{|k,v| add_field("C_#{k}",v)}
        end

        def callback_params(params={})
          params.each{|k,v| add_field("M_#{k}",v)}
        end

        def combined_params(params={})
          params.each{|k,v| add_field("MC_#{k}",v)}
        end
      end

      class Notification < OffsitePayments::Notification
        def complete?
          status == 'Completed'
        end

        def account
          params['instId']
        end

        def item_id
          params['cartId']
        end

        def transaction_id
          params['transId']
        end

        # Time this payment was received by the client in UTC time.
        def received_at
          Time.at(params['transTime'].to_i / 1000).utc
        end

        # Callback password set in the WorldPay CMS
        def security_key
          params['callbackPW']
        end

        # the money amount we received in X.2 decimal.
        def gross
          params['amount']
        end

        def currency
          params['currency']
        end

        # Was this a test transaction?
        def test?
          params.key?('testMode') && params['testMode'] != '0'
        end

        def status
          params['transStatus'] == 'Y' ? 'Completed' : 'Cancelled'
        end

        def name
          params['name']
        end

        def address
          params['address']
        end

        def postcode
          params['postcode']
        end

        def country
          params['country']
        end

        def phone_number
          params['tel']
        end

        def fax_number
          params['fax']
        end

        def email_address
          params['email']
        end

        def card_type
          params['cardType']
        end

        # WorldPay extended fraud checks returned as a 4 character string
        #   1st char: Credit card CVV check
        #   2nd char: Postcode AVS check
        #   3rd char: Address AVS check
        #   4th char: Country comparison check
        # Possible values are:
        #   :not_supported   -  0
        #   :not_checked     -  1
        #   :matched         -  2
        #   :not_matched     -  4
        #   :partial_match   -  8
        def cvv_status
          return avs_value_to_symbol(params['AVS'][0].chr)
        end

        def postcode_status
          return avs_value_to_symbol(params['AVS'][1].chr)
        end

        def address_status
          return avs_value_to_symbol(params['AVS'][2].chr)
        end

        def country_status
          return avs_value_to_symbol(params['AVS'][3].chr)
        end

        def acknowledge(authcode = nil)
          return true
        end

        # WorldPay supports the passing of custom parameters through to the callback script
        def custom_params
          return @custom_params ||= read_custom_params
        end

        # Check if the request comes from IP range 195.35.90.0 – 195.35.91.255
        def valid_sender?(ip)
          return true if OffsitePayments.mode == :test 
          IPAddr.new("195.35.90.0/23").include?(IPAddr.new(ip))
        end

        private

        # Take the posted data and move the relevant data into a hash
        def parse(post)
          @raw = post
          for line in post.split('&')
            key, value = *line.scan( %r{^(\w+)\=(.*)$} ).flatten
            params[key] = value
          end
        end

        # Read the custom params into a hash
        def read_custom_params
          custom = {}
          params.each do |key, value|
            if /\A(M_|MC_|CM_)/ === key
              custom[key.gsub(/\A(M_|MC_|CM_)/, '').to_sym] = value
            end
          end
          custom
        end

        # Convert a AVS value to a symbol - see above for more about AVS
        def avs_value_to_symbol(value)
          case value.to_s
          when '8'
            :partial_match
          when '4'
            :no_match
          when '2'
            :matched
          when '1'
            :not_checked
          else
            :not_supported
          end
        end
      end
    end
  end
end
