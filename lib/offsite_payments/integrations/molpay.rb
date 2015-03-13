module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module Molpay

      mattr_accessor :acknowledge_url 

      self.acknowledge_url = 'https://www.onlinepayment.com.my/MOLPay/API/chkstat/returnipn.php' 

      def self.notification(post)
        Notification.new(post)
      end

      def self.return(query_string, options={})
        Return.new(query_string, options)
      end

      # Example.
      #
      #  (Optional Parameter) = channel //will generate URL to go directly to specific channel, e.g maybank2u, cimb 
      #  Please refer MOLPay API spec for the channel routing
      #
      #  payment_service_for('ORDER_ID', 'MOLPAY_MERCHANT_ID', :service => :molpay,  :amount => 1.01, :currency => 'MYR', :credential2 => 'MOLPAY_VERIFICATION_KEY', :channel => 'maybank2u.php') do |service|
      #
      #    service.customer :name              => 'Your Name',
      #                     :email             => 'name@molpay.com',
      #                     :phone             => '60355218438'
      #
      #    service.description = "Payment for Item 001"
      #
      #    service.country = "MY"
      #
      #    service.language = "en"
      #
      #    service.return_url = 'http://yourstore.com/return'
      #
      # end
      #
      class Helper < OffsitePayments::Helper
        include ActiveUtils::RequiresParameters
        
        #Currencies supported (ISO)
        #MYR, USD, SGD, PHP, VND, IDR, AUD

        SUPPORTED_CURRENCIES = ['MYR', 'USD', 'SGD', 'PHP', 'VND', 'IDR', 'AUD']

        #Languages supported 
        #en English (default)
        #cn Simplified Chinese
        SUPPORTED_LANGUAGES = ['en', 'cn']

        SERVICE_URL = 'https://www.onlinepayment.com.my/MOLPay/pay/'.freeze

        mapping :account, 'merchantid'
        mapping :amount, 'amount'
        mapping :order, 'orderid'
        mapping :customer, :name  => 'bill_name',
                           :email => 'bill_email',
                           :phone => 'bill_mobile'

        mapping :description, 'bill_desc'
        mapping :language, 'langcode'
        mapping :country, 'country'
        mapping :currency, 'cur'
        mapping :return_url, 'returnurl'
        mapping :signature, 'vcode'


        attr_reader :amount_in_cents, :verify_key, :channel

        def credential_based_url
          service_url = SERVICE_URL + @fields[mappings[:account]] + "/"
          service_url = service_url + @channel unless @channel.blank?
          service_url
        end

        def initialize(order, account, options = {})
          requires!(options, :amount, :currency, :credential2)
          @verify_key = options[:credential2] if options[:credential2]
          @amount_in_cents = options[:amount]
          @channel = options[:channel] if options[:channel]
          options.delete(:channel) #delete channel to left only valid keys
          super
        end

        def form_fields
          add_field mappings[:signature], signature
          @fields
        end

        def amount=(money)
          #Molpay minimum amount is 1.01
          if money.is_a?(String) or money.to_f < 1.01
            raise ArgumentError, "money amount must be either a Money object or a positive integer."
          end
          add_field mappings[:amount], sprintf("%.2f", money.to_f)
        end

        def currency=(cur)
          raise ArgumentError, "unsupported currency" unless SUPPORTED_CURRENCIES.include?(cur)
          add_field mappings[:currency], cur
        end

        def language=(lang)
          raise ArgumentError, "unsupported language" unless SUPPORTED_LANGUAGES.include?(lang)
          add_field mappings[:language], lang
        end


        private

        def signature
          Digest::MD5.hexdigest("#{@fields[mappings[:amount]]}#{@fields[mappings[:account]]}#{@fields[mappings[:order]]}#{@verify_key}")
        end
      end

      # Example
      # ========
      #
      # notification = Molpay::Notification.new(request.raw_post, options = {:credential2 => "SECRET_KEY"})
      #
      # @order = Order.find(notification.item_id)
      #
      # begin
      #   if notification.acknowledge
      #     @order.status = 'success'
      #     redirect_to @order
      #   else
      #     @order.status = 'failed'
      #     render :text => "Failed Transaction"
      #   end
      # ensure
      #   @order.save
      # end

      class Notification < OffsitePayments::Notification
        include ActiveUtils::PostsData

        def complete?
          status == 'Completed'
        end

        def item_id
          params['orderid']
        end

        def transaction_id
          params['tranID']
        end

        def account
          params["domain"]
        end

        # the money amount we received in X.2 decimal.
        def gross
          params['amount']
        end

        def currency
          params['currency']
        end

        def channel
          params['channel']
        end

        # When was this payment received by the client.
        def received_at
          params['paydate']
        end

        def auth_code
          params['appcode']
        end

        def error_code  
          params['error_code']
        end

        def error_desc
          params['error_desc']
        end

        def security_key
          params['skey']
        end

        def test?
          gross.blank? && auth_code.blank? && error_code.blank? && error_desc.blank? && security_key.blank?
        end

        def status
          params['status'] == '00' ? 'Completed' : 'Failed' 
        end

        # Acknowledge the transaction to Molpay. This method has to be called after a new
        # apc arrives. Molpay will verify that all the information we received are correct
        #
        # Example:
        #
        #   def ipn
        #     notify = MolpayNotification.new(request.raw_post)
        #
        #     if notify.acknowledge
        #       ... process order ... if notify.complete?
        #     else
        #       ... log possible hacking attempt ...
        #     end
        def acknowledge(authcode = nil)

          payload =  raw + '&treq=1'

          #this is to notify MOLPay that return has been received
          ssl_post(Molpay.acknowledge_url, payload,
            'Content-Length' => "#{payload.size}",
            'User-Agent'     => "Shopify/OffsitePayments"
          )

          status == 'Completed' && security_key == generate_signature
          
        end

        protected

        def generate_signature
          Digest::MD5.hexdigest("#{gross}#{account}#{item_id}#{@options[:credential2]}")
        end 
      end

      class Return < OffsitePayments::Return

        def initialize(query_string, options = {})
          super
          @notification = Notification.new(query_string, options)
        end

        def success?
          @notification.acknowledge
        end
      end

    end
  end
end
