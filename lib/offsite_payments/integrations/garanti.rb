require File.dirname(__FILE__) + '/garanti/helper.rb'
require File.dirname(__FILE__) + '/garanti/notification.rb'

module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module Garanti

      mattr_accessor :service_url
      self.service_url = 'https://sanalposprov.garanti.com.tr/servlet/gt3dengine'

  # The countries the gateway supports merchants from as 2 digit ISO country codes
      self.supported_countries = ['US','TR']

      # The card types supported by the payment gateway
      self.supported_cardtypes = [:visa, :master, :american_express, :discover]

      # The homepage URL of the gateway
      self.homepage_url = 'https://sanalposweb.garanti.com.tr'

      # The name of the gateway
      self.display_name = 'Garanti Sanal POS (Offsite)'

      self.default_currency = 'TRL'

      self.money_format = :cents
 
      CURRENCY_CODES = {
        'TRL' => 949,
        'TL'  => 949,
        'USD' => 840,
        'EUR' => 978,
        'GBP' => 826,
        'JPY' => 392
      }

      def self.notification(post)
        Notification.new(post)
      end

      class Helper < OffsitePayments::Helper

        def initialize(options = {})
        requires!(options, :login, :password, :terminal_id, :merchant_id)
        super
      end

      def purchase(money, options = {})
        options = options.merge(:gvp_order_type => "sales")
        commit(money, build_sale_request(money, options))
      end

      private

      def security_data
        rjusted_terminal_id = @options[:terminal_id].to_s.rjust(9, "0")
        Digest::SHA1.hexdigest(@options[:password].to_s + rjusted_terminal_id).upcase
      end

      def generate_hash_data(order_id, terminal_id,  amount)
        data = [order_id, terminal_id,  amount,].join
        Digest::SHA1.hexdigest(data).upcase
      end

      def build_xml_request(money, options, &block)
       
        hash_data   = generate_hash_data(format_order_id(options[:order_id]), @options[:terminal_id], amount(money))

        xml = Builder::XmlMarkup.new(:indent => 2)
        xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8"

        xml.tag! 'GVPSRequest' do
          xml.tag! 'Mode', test? ? 'TEST' : 'PROD'
          xml.tag! 'Version', 'V0.01'
          xml.tag! 'Terminal' do
            xml.tag! 'ProvUserID', 'PROVOOS'
            xml.tag! 'HashData', hash_data
            xml.tag! 'UserID', @options[:login]
            xml.tag! 'ID', @options[:terminal_id]
            xml.tag! 'MerchantID', @options[:merchant_id]
          end

          if block_given?
            yield xml
          else
            xml.target!
          end
        end
      end

      def build_sale_request(money, options)
        build_xml_request(money, options) do |xml|
          add_customer_data(xml, options)
          add_order_data(xml, options) do
            add_addresses(xml, options)
          end
           add_transaction_data(xml, money, options)

          xml.target!
        end
      end

     

      def add_customer_data(xml, options)
        xml.tag! 'Customer' do
          xml.tag! 'IPAddress', options[:ip] || '1.1.1.1'
          xml.tag! 'EmailAddress', options[:email]
        end
      end

      def add_order_data(xml, options, &block)
        xml.tag! 'Order' do
          xml.tag! 'OrderID', format_order_id(options[:order_id])
          xml.tag! 'GroupID'

          if block_given?
            yield xml
          end
        end
      end

      
      def format_exp(value)
        format(value, :two_digits)
      end

      # OrderId field must be A-Za-z0-9_ format and max 36 char
      def format_order_id(order_id)
        order_id.to_s.gsub(/[^A-Za-z0-9_]/, '')[0...36]
      end

      def add_addresses(xml, options)
        xml.tag! 'AddressList' do
          if billing_address = options[:billing_address] || options[:address]
            xml.tag! 'Address' do
              xml.tag! 'Type', 'B'
              add_address(xml, billing_address)
            end
          end

          if options[:shipping_address]
            xml.tag! 'Address' do
              xml.tag! 'Type', 'S'
              add_address(xml, options[:shipping_address])
            end
          end
        end
      end

      def add_address(xml, address)
        xml.tag! 'Name', normalize(address[:name])
        address_text = address[:address1]
        address_text << " #{ address[:address2]}" if address[:address2]
        xml.tag! 'Text', normalize(address_text)
        xml.tag! 'City', normalize(address[:city])
        xml.tag! 'District', normalize(address[:state])
        xml.tag! 'PostalCode', address[:zip]
        xml.tag! 'Country', normalize(address[:country])
        xml.tag! 'Company', normalize(address[:company])
        xml.tag! 'PhoneNumber', address[:phone].to_s.gsub(/[^0-9]/, '') if address[:phone]
      end

      def normalize(text)
        return unless text

        if ActiveSupport::Inflector.method(:transliterate).arity == -2
          ActiveSupport::Inflector.transliterate(text,'')
        elsif RUBY_VERSION >= '1.9'
          text.gsub(/[^\x00-\x7F]+/, '')
        else
          ActiveSupport::Inflector.transliterate(text).to_s
        end
      end

      def add_transaction_data(xml, money, options)
        xml.tag! 'Transaction' do
          xml.tag! 'Type', options[:gvp_order_type]
          xml.tag! 'Amount', amount(money)
          xml.tag! 'CurrencyCode', currency_code(options[:currency] || currency(money))
          xml.tag! 'CardholderPresentCode', 0
          xml.tag! 'successurl',
          xml.tag! 'errorurl',
        end
      end

  
      end

      class Notification < OffsitePayments::Notification

        def commit(money,request)
        raw_response = ssl_post(self.live_url, "data=" + request)
        response = parse(raw_response)

        success = success?(response)

        Response.new(success,
                     success ? 'Approved' : "Declined (Reason: #{response[:reason_code]} - #{response[:error_msg]} - #{response[:sys_err_msg]})",
                     response,
                     :test => test?,
                     :authorization => response[:order_id])
      end

        def currency(currency)
        CURRENCY_CODES[currency] || CURRENCY_CODES[default_currency]
      end

         
       def parse(body)
        xml = REXML::Document.new(body)

        response = {}
        xml.root.elements.to_a.each do |node|
          parse_element(response, node)
        end
        response
      end

      def parse_element(response, node)
        if node.has_elements?
          node.elements.each{|element| parse_element(response, element) }
        else
          response[node.name.underscore.to_sym] = node.text
        end
      end

      def complete?
          (status == "Completed")
        end

        def status
          params["Status"]
        end

        def transaction_id
          params['TransactionId']
        end

        def item_id
          params['OrderId']
        end

         def gross
          params['Amount']
        end

        def error
          params['Error']
        end

      def success?(response)
        response[:message] == "Approved"
      end
      end
    end
  end
end
