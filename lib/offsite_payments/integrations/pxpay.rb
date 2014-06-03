require 'rexml/document'

module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module Pxpay
      def self.token_url
        'https://sec.paymentexpress.com/pxpay/pxaccess.aspx'
      end

      def self.notification(post, options={})
        Notification.new(post, options)
      end

      def self.return(query_string, options={})
        Return.new(query_string, options)
      end

      class Helper < OffsitePayments::Helper
        include ActiveMerchant::PostsData

        attr_reader :token_parameters, :redirect_parameters

        def initialize(order, account, options = {})
          @token_parameters = {
            'PxPayUserId'       => account,
            'PxPayKey'          => options[:credential2],
            'CurrencyInput'     => options[:currency],
            'MerchantReference' => order,
            'EmailAddress'      => options[:customer_email],
            'TxnData1'          => options[:custom1],
            'TxnData2'          => options[:custom2],
            'TxnData3'          => options[:custom3],
            'AmountInput'       => "%.2f" % options[:amount].to_f.round(2),
            'EnableAddBillCard' => '0',
            'TxnType'           => 'Purchase',
            'UrlSuccess'        => options[:return_url],
            'UrlFail'           => options[:return_url]
          }
          @redirect_parameters = {}

          super

          raise ArgumentError, "error - must specify return_url"        if token_parameters['UrlSuccess'].blank?
          raise ArgumentError, "error - must specify cancel_return_url" if token_parameters['UrlFail'].blank?
        end

        def credential_based_url
          raw_response = ssl_post(Pxpay.token_url, generate_request)
          result = parse_response(raw_response)

          raise ActionViewHelperError, "error - failed to get token - message was #{result[:redirect]}" unless result[:valid] == "1"

          url = URI.parse(result[:redirect])

          if url.query
            @redirect_parameters = CGI.parse(url.query)
            url.query = nil
          end

          url.to_s
        end

        def form_method
          "GET"
        end

        def form_fields
          redirect_parameters
        end

        private
        def generate_request
          xml = REXML::Document.new
          root = xml.add_element('GenerateRequest')

          token_parameters.each do | k, v |
            next if v.blank?

            v = v.to_s.slice(0, 50) if k == "MerchantReference"
            root.add_element(k).text = v
          end

          xml.to_s
        end

        def parse_response(raw_response)
          xml = REXML::Document.new(raw_response)
          root = REXML::XPath.first(xml, "//Request")
          valid = root.attributes["valid"]
          redirect = root.elements["URI"].try(:text)
          valid, redirect = "0", root.elements["ResponseText"].try(:text) unless redirect

          # example valid response:
          # <Request valid="1"><URI>https://sec.paymentexpress.com/pxpay/pxpay.aspx?userid=PxpayUser&amp;request=REQUEST_TOKEN</URI></Request>
          # <Request valid='1'><Reco>IP</Reco><ResponseText>Invalid Access Info</ResponseText></Request>

          # example invalid response:
          # <Request valid="0"><URI>Invalid TxnType</URI></Request>

          {:valid => valid, :redirect => redirect}
        end
      end

      class Notification < OffsitePayments::Notification
        include ActiveMerchant::PostsData
        include ActiveMerchant::RequiresParameters

        def initialize(query_string, options={})
          # PxPay appends ?result=...&userid=... to whatever return_url was specified, even if that URL ended with a ?query.
          # So switch the first ? if present to a &
          query_string[/\?/] = '&' if query_string[/\?/]
          super

          @encrypted_params = @params
          @params = {}

          requires! @encrypted_params, "result"
          requires! @options, :credential1, :credential2

          decrypt_transaction_result(@encrypted_params["result"])
        end

        # was the notification a validly formed request?
        def acknowledge(authcode = nil)
          @valid == '1'
        end

        def status
          return 'Failed' unless success?
          return 'Completed' if complete?
          'Error'
        end

        def complete?
          @params['TxnType'] == 'Purchase' && success?
        end

        def cancelled?
          !success?
        end

        # for field definitions see
        # http://www.paymentexpress.com/Technical_Resources/Ecommerce_Hosted/PxPay

        def success?
          @params['Success'] == '1'
        end

        def gross
          @params['AmountSettlement']
        end

        def currency
          @params['CurrencySettlement']
        end

        def account
          @params['userid']
        end

        def item_id
          @params['MerchantReference']
        end

        def currency_input
          @params['CurrencyInput']
        end

        def auth_code
          @params['AuthCode']
        end

        def card_type
          @params['CardName']
        end

        def card_holder_name
          @params['CardHolderName']
        end

        def card_number
          @params['CardNumber']
        end

        def expiry_date
          @params['DateExpiry']
        end

        def client_ip
          @params['ClientInfo']
        end

        def order_id
          item_id
        end

        def payer_email
          @params['EmailAddress']
        end

        def transaction_id
          @params['DpsTxnRef']
        end

        def settlement_date
          @params['DateSettlement']
        end

        # Indication of the uniqueness of a card number
        def txn_mac
          @params['TxnMac']
        end

        def message
          @params['ResponseText']
        end

        def optional_data
          [@params['TxnData1'],@fields['TxnData2'],@fields['TxnData3']]
        end

        # When was this payment was received by the client.
        def received_at
          settlement_date
        end

        # Was this a test transaction?
        def test?
          nil
        end

        private

        def decrypt_transaction_result(encrypted_result)
          request_xml = REXML::Document.new
          root = request_xml.add_element('ProcessResponse')

          root.add_element('PxPayUserId').text = @options[:credential1]
          root.add_element('PxPayKey').text = @options[:credential2]
          root.add_element('Response').text = encrypted_result

          @raw = ssl_post(Pxpay.token_url, request_xml.to_s)

          response_xml = REXML::Document.new(@raw)
          root = REXML::XPath.first(response_xml)
          @valid = root.attributes["valid"]
          @params = {}
          root.elements.each { |e| @params[e.name] = e.text }
        end
      end

      class Return < OffsitePayments::Return
        def initialize(query_string, options={})
          @notification = Notification.new(query_string, options)
        end

        def success?
          @notification && @notification.complete?
        end

        def cancelled?
          @notification && @notification.cancelled?
        end

        def message
          @notification.message
        end
      end
    end
  end
end
