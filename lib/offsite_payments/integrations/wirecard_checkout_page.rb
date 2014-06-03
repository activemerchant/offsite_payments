module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    # Shop System Plugins - Terms of use
    #
    # This terms of use regulates warranty and liability between Wirecard Central Eastern Europe (subsequently referred to as WDCEE) and it's
    # contractual partners (subsequently referred to as customer or customers) which are related to the use of plugins provided by WDCEE.
    #
    # The Plugin is provided by WDCEE free of charge for it's customers and must be used for the purpose of WDCEE's payment platform
    # integration only. It explicitly is not part of the general contract between WDCEE and it's customer. The plugin has successfully been tested
    # under specific circumstances which are defined as the shopsystem's standard configuration (vendor's delivery state). The Customer is
    # responsible for testing the plugin's functionality before putting it into production environment.
    # The customer uses the plugin at own risk. WDCEE does not guarantee it's full functionality neither does WDCEE assume liability for any
    # disadvantage related to the use of this plugin. By installing the plugin into the shopsystem the customer agrees to the terms of use.
    # Please do not use this plugin if you do not agree to the terms of use!
    module WirecardCheckoutPage
      mattr_accessor :service_url
      self.service_url = 'https://checkout.wirecard.com/page/init.php'

      def self.notification(post, options)
        Notification.new(post, options)
      end

      def self.return(postdata, options)
        Return.new(postdata, options)
      end

      module Common
        mattr_accessor :paymenttypes
        self.paymenttypes = %w(
            SELECT
            CCARD
            BANCONTACT_MISTERCASH
            C2P
            CCARD-MOTO
            EKONTO
            ELV
            EPS
            GIROPAY
            IDL
            INSTALLMENT
            INSTANTBANK
            INVOICE
            MAESTRO
            MONETA
            MPASS
            PRZELEWY24
            PAYPAL
            PBX
            POLI
            PSC
            QUICK
            SKRILLDIRECT
            SKRILLWALLET
            SOFORTUEBERWEISUNG)

        def message
          @message
        end

        def verify_response(params, secret)
          logstr = ''
          params.each { |key, value|
            logstr += "#{key} #{value}\n"
          }

          @paymentstate = 'FAILURE'

          unless params.has_key?('paymentState')
            @message = "paymentState is missing"
            return false
          end

          if params['paymentState'] == 'SUCCESS' || params['paymentState'] == 'PENDING'
            unless params.has_key?('responseFingerprint')
              @message = "responseFingerprint is missing"
              return false
            end

            unless params.has_key?('responseFingerprintOrder')
              @message = "responseFingerprintOrder is missing"
              return false
            end

          end

          if params['paymentState'] == 'SUCCESS' || params['paymentState'] == 'PENDING'
            fields = params['responseFingerprintOrder'].split(",")
            values = ''
            fields.each { |f|
              values += f == 'secret' ? secret : params[f]
            }


            if Digest::MD5.hexdigest(values) != params['responseFingerprint']
              @message = "responseFingerprint verification failed"
              return false
            end
          end

          @paymentstate = params['paymentState']
          true
        end
      end

      class Helper < OffsitePayments::Helper
        include Common

        PLUGIN_NAME = 'ActiveMerchant_WirecardCheckoutPage'
        PLUGIN_VERSION = '1.0.0'

        # Replace with the real mapping
        mapping :account, 'customerId'
        mapping :amount, 'amount'

        mapping :order, 'xActiveMerchantOrderId'

        mapping :customer, :first_name => 'consumerBillingFirstName',
                :last_name => 'consumerBillingLastName',
                :email => 'consumerEmail',
                :phone => 'consumerBillingPhone',
                :ipaddress => 'consumerIpAddress',
                :user_agent => 'consumerUserAgent',
                :fax => 'consumerBillingFax',
                :birthdate => 'consumerBirthDate' # mandatory for INVOICE and INSTALLMENT

        mapping :billing_address, :city => 'consumerBillingCity',
                :address1 => 'consumerBillingAddress1',
                :address2 => 'consumerBillingAddress2',
                :state => 'consumerBillingState',
                :zip => 'consumerBillingZipCode',
                :country => 'consumerBillingCountry'

        mapping :shipping_address, :first_name => 'consumerShippingFirstName',
                :last_name => 'consumerShippingLastName',
                :address1 => 'consumerShippingAddress1',
                :address2 => 'consumerShippingAddress2',
                :city => 'consumerShippingCity',
                :state => 'consumerShippingState',
                :country => 'consumerShippingCountry',
                :zip => 'consumerShippingZipCode',
                :phone => 'consumerShippingPhone',
                :fax => 'consumerShippingFax'

        mapping :currency, 'currency'
        mapping :language, 'language' # language for displayed texts on payment page

        mapping :description, 'orderDescription' # unique description of the consumer's order in a human readable form

        mapping :shop_service_url, 'serviceUrl' # URL of your service page containing contact information

        mapping :notify_url, 'confirmUrl'
        mapping :return_url, 'successUrl'

        # defaulting to return_url
        mapping :cancel_return_url, 'cancelUrl'
        mapping :pending_url, 'pendingUrl'
        mapping :failure_url, 'failureUrl'

        # optional parameters
        mapping :window_name, 'windowName' # window.name of browser window where payment page is opened
        mapping :duplicate_request_check, 'duplicateRequestCheck' # check for duplicate requests done by your consumer
        mapping :customer_statement, 'customerStatement' # text displayed on invoice of financial institution of your consumer
        mapping :order_reference, 'orderReference' # unique order reference id sent from merchant to financial institution
        mapping :display_text, 'displayText' # text displayed to your consumer within the payment page
        mapping :image_url, 'imageUrl' #  URL of your web shop where your web shop logo is located
        mapping :max_retries, 'maxRetries' # maximum number of attempted payments for the same order
        mapping :auto_deposit, 'autoDeposit' # enable automated debiting of payments
        mapping :financial_institution, 'financialInstitution' # based on pre-selected payment type a sub-selection of financial institutions regarding to pre-selected payment type

        # not used
        mapping :tax, ''
        mapping :shipping, ''

        def initialize(order, customer_id, options = {})
          @paymenttype = options.delete(:paymenttype)

          raise "Unknown Paymenttype: " + @paymenttype if paymenttypes.find_index(@paymenttype) == nil

          @secret = options.delete(:secret)
          @customer_id = customer_id
          @shop_id = options.delete(:shop_id)
          super
        end

        def add_version(shop_name, shop_version)
          add_field('pluginVersion', Base64.encode64(shop_name + ';' + shop_version + ';ActiveMerchant;' + PLUGIN_NAME + ';' + PLUGIN_VERSION))
        end

        def add_standard_fields
          addfields = {}
          addfields['shopId'] = @shop_id if !@shop_id.blank?
          addfields['paymentType'] = @paymenttype

          addfields[mappings[:pending_url]] = @fields[mappings[:return_url]] unless @fields.has_key?(mappings[:pending_url])
          addfields[mappings[:cancel_return_url]] = @fields[mappings[:return_url]] unless @fields.has_key?(mappings[:cancel_return_url])
          addfields[mappings[:failure_url]] = @fields[mappings[:return_url]] unless @fields.has_key?(mappings[:failure_url])

          addfields
        end

        def add_request_fingerprint(fpfields)
          addfields = {}
          fingerprint_order = %w(secret)
          fingerprint_values = @secret.to_s
          fpfields.each { |key, value|
            next if key == 'pluginVersion'
            fingerprint_order.append key
            fingerprint_values += value.to_s
          }

          fingerprint_order.append 'requestFingerprintOrder'
          fingerprint_values += fingerprint_order.join(',')

          addfields['requestFingerprintOrder'] = fingerprint_order.join(',')
          addfields['requestFingerprint'] = Digest::MD5.hexdigest(fingerprint_values)

          addfields
        end

        def form_fields
          result = {}
          result.merge!(@fields)
          result.merge!(add_standard_fields)
          result.merge!(add_request_fingerprint(result))
          result
        end

        def secret
          @secret
        end

        def customer_id
          @customer_id
        end

        def shop_id
          @shop_id
        end
      end

      class Notification < OffsitePayments::Notification
        include Common

        def complete?
          @paymentstate == 'SUCCESS'
        end

        def item_id
          params['xActiveMerchantOrderId']
        end

        def transaction_id
          params['orderNumber']
        end

        # When was this payment received by the client.
        def received_at
          nil
        end

        # the money amount we received in X.2 decimal.
        def gross
          params['amount']
        end

        # Was this a test transaction?
        def test?
          false
        end

        def status
          case @paymentstate
            when 'SUCCESS'
              'Completed'
            when 'PENDING'
              'Pending'
            when 'CANCEL'
              'Cancelled'
            when 'FAILURE'
              'Failed'
            else
              'Error'
          end
        end

        def status_code
          @paymentstate
        end

        # Acknowledge the transaction to WirecardCheckoutPage. This method has to be called after a new
        # apc arrives. WirecardCheckoutPage will verify that all the information we received are correct and will return a
        # ok or a fail.
        #
        # Example:
        #
        #   def ipn
        #     notify = WirecardCheckoutPageNotification.new(request.raw_post, options)
        #
        #     if notify.acknowledge
        #       ... process order ... if notify.complete?
        #     else
        #       ... log possible hacking attempt ...
        #     end
        def acknowledge
          verify_response(params, @options[:secret])
        end

        def response(umessage = nil)
          if @message || umessage
            '<QPAY-CONFIRMATION-RESPONSE result="NOK" message="' + CGI.escapeHTML(umessage ? umessage : @message) + '"/>'
          else
            '<QPAY-CONFIRMATION-RESPONSE result="OK"/>'
          end
        end

        def method_missing(method_id, *args)
          return params[method_id.to_s] if params.has_key?(method_id.to_s)
        end

        private

        # Take the posted data and move the relevant data into a hash
        def parse(post)
          @raw = post.to_s
          for line in @raw.split('&')
            key, value = *line.scan( %r{^([A-Za-z0-9_.]+)\=(.*)$} ).flatten
            params[key] = CGI.unescape(value)
          end
        end
      end

      class Return < OffsitePayments::Return
        include Common

        def initialize(postdata, options = {})
          @params  = parse(postdata)
          @options = options
          verify_response(@params, options[:secret])
        end

        def success?
          @paymentstate == 'SUCCESS'
        end

        def cancelled?
          @paymentstate == 'CANCEL'
        end

        def pending?
          @paymentstate == 'PENDING'
        end

        def method_missing(method_id, *args)
          return params[method_id.to_s] if params.has_key?(method_id.to_s)
        end
      end
    end
  end
end
