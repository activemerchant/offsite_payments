# encoding: utf-8

module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module PagSeguro
      mattr_accessor :service_production_url
      self.service_production_url = 'https://pagseguro.uol.com.br/v2/checkout/payment.html'

      mattr_accessor :service_test_url
      self.service_test_url = 'https://sandbox.pagseguro.uol.com.br/v2/checkout/payment.html'

      mattr_accessor :invoicing_production_url
      self.invoicing_production_url = 'https://ws.pagseguro.uol.com.br/v2/checkout/'

      mattr_accessor :invoicing_test_url
      self.invoicing_test_url = 'https://ws.sandbox.pagseguro.uol.com.br/v2/checkout/'

      mattr_accessor :notification_production_url
      self.notification_production_url = 'https://ws.pagseguro.uol.com.br/v2/transactions/notifications/'

      mattr_accessor :notification_test_url
      self.notification_test_url = 'https://ws.sandbox.pagseguro.uol.com.br/v2/transactions/notifications/'

      def self.service_url
        test? ? service_test_url : service_production_url
      end

      def self.invoicing_url
        test? ? invoicing_test_url : invoicing_production_url
      end

      def self.notification_url
        test? ? notification_test_url : notification_production_url
      end

      def self.notification(query_string, options = {})
        Notification.new(query_string, options)
      end

      def self.return(query_string, options = {})
        Return.new(query_string, options)
      end

      def self.test?
        OffsitePayments.mode == :test
      end

      class Helper < OffsitePayments::Helper
        def initialize(order_id, account, options)
          super
          @account = account

          add_field('itemAmount1', sprintf("%0.02f", options[:amount]))
          add_field('itemId1', '1')
          add_field('itemQuantity1', '1')
          add_field('shippingType', '3')
          add_field('currency', 'BRL')
        end

        mapping :account, 'email'
        mapping :credential2, 'token'

        mapping :order, 'reference'

        mapping :billing_address, :city     => 'shippingAddressCity',
                                  :address1 => 'shippingAddressStreet',
                                  :address2 => 'shippingAddressNumber',
                                  :state    => 'shippingAddressState',
                                  :zip      => 'shippingAddressPostalCode',
                                  :country  => 'shippingAddressCountry'

        mapping :notify_url, 'notificationURL'
        mapping :return_url, 'redirectURL'
        mapping :description, 'itemDescription1'

        def form_fields
          invoice_id = fetch_token

          {"code" => invoice_id}
        end

        def shipping(value)
          add_field("shippingCost", sprintf("%0.02f", value))
        end

        def customer(params = {})
          phone = area_code_and_number(params[:phone])
          full_name = remove_excessive_whitespace("#{params[:first_name]} #{params[:last_name]}")

          add_field("senderAreaCode", phone[0])
          add_field("senderPhone", phone[1])
          add_field("senderEmail", params[:email])
          add_field('senderName', full_name)
        end

        def fetch_token
          uri = URI.parse(PagSeguro.invoicing_url)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true

          request = Net::HTTP::Post.new(uri.request_uri)
          request.content_type = "application/x-www-form-urlencoded"
          request.set_form_data @fields

          response = http.request(request)
          xml = Nokogiri::XML.parse(response.body)

          check_for_errors(response, xml)

          extract_token(xml)
        rescue Timeout::Error, Errno::ECONNRESET => e
          raise ActionViewHelperError, "Erro ao conectar-se ao PagSeguro. Por favor, tente novamente."
        end

        def area_code_and_number(phone)
          phone.gsub!(/[^\d]/, '')

          ddd    = phone.slice(0..1)
          number = phone.slice(2..12)

          [ddd, number]
        end

        def check_for_errors(response, xml)
          return if response.code == "200"

          case response.code
          when "400"
            raise ActionViewHelperError, humanize_errors(xml)
          when "401"
            raise ActionViewHelperError, "Token do PagSeguro inválido."
          else
            raise ActiveMerchant::ResponseError, response
          end
        end

        def extract_token(xml)
          xml.css("code").text
        end

        def humanize_errors(xml)
          # reference: https://pagseguro.uol.com.br/v2/guia-de-integracao/codigos-de-erro.html

          xml.css("errors").children.map do |error|
            case error.css('code').text
            when "11013"
              "Código de área inválido"
            when "11014"
              "Número de telefone inválido. Formato esperado: (DD) XXXX-XXXX"
            when "11017"
              "Código postal (CEP) inválido."
            else
              error.css('message').text
            end
          end.join(", ")
        end

        def remove_excessive_whitespace(text)
          text.gsub(/\s{2,}/, ' ').strip
        end
      end

      class Notification < OffsitePayments::Notification
        def initialize(post, options = {})
          notify_code = parse_http_query(post)["notificationCode"]
          email = options[:credential1]
          token = options[:credential2]

          uri = URI.join(PagSeguro.notification_url, notify_code)
          parse_xml(web_get(uri, email: email, token: token))
        end

        def complete?
          status == "Completed"
        end

        def item_id
          params["transaction"]["reference"]
        end

        def transaction_id
          params["transaction"]["code"]
        end

        def received_at
          params["transaction"]["date"]
        end

        def payer_email
          params["sender"]["email"]
        end

        def gross
          params["transaction"]["grossAmount"]
        end

        def currency
          "BRL"
        end

        def payment_method_type
          params["transaction"]["paymentMethod"]["type"]
        end

        def payment_method_code
          params["transaction"]["paymentMethod"]["code"]
        end

        def status
          case params["transaction"]["status"]
          when "1", "2"
            "Pending"
          when "3"
            "Completed"
          when "4"
            "Available"
          when "5"
            "Dispute"
          when "6"
            "Reversed"
          when "7"
            "Failed"
          end
        end

        # There's no acknowledge for PagSeguro
        def acknowledge
          true
        end

        private

        def web_get(uri, params)
          uri.query = URI.encode_www_form(params)

          response = Net::HTTP.get_response(uri)
          response.body
        end

        # Take the posted data and move the relevant data into a hash
        def parse_xml(post)
          @params = Hash.from_xml(post)
        end

        def parse_http_query(post)
          @raw = post
          params = {}
          for line in post.split('&')
            key, value = *line.scan( %r{^(\w+)\=(.*)$} ).flatten
            params[key] = value
          end
          params
        end
      end
    end
  end
end
