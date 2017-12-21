module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module PayuIn
      mattr_accessor :test_url
      mattr_accessor :production_url

      self.test_url = 'https://test.payu.in/_payment.php'
      self.production_url = 'https://secure.payu.in/_payment.php'

      def self.service_url
        OffsitePayments.mode == :production ? self.production_url : self.test_url
      end

      def self.notification(post, options = {})
        Notification.new(post, options)
      end

      def self.return(post, options = {})
        Return.new(post, options)
      end

      def self.checksum(merchant_id, secret_key, payload_items )
        Digest::SHA512.hexdigest([merchant_id, *payload_items, secret_key].join("|"))
      end

      class Helper < OffsitePayments::Helper

        CHECKSUM_FIELDS = [ 'txnid', 'amount', 'productinfo', 'firstname', 'email', 'udf1', 'udf2', 'udf3', 'udf4',
                            'udf5', 'udf6', 'udf7', 'udf8', 'udf9', 'udf10']

        mapping :amount, 'amount'
        mapping :account, 'key'
        mapping :order, 'txnid'
        mapping :description, 'productinfo'

        mapping :customer, :first_name => 'firstname',
          :last_name  => 'lastname',
          :email => 'email',
          :phone => 'phone'

        mapping :billing_address, :city => 'city',
          :address1 => 'address1',
          :address2 => 'address2',
          :state => 'state',
          :zip => 'zipcode',
          :country => 'country'

        # Which tab you want to be open default on PayU
        # CC (CreditCard) or NB (NetBanking)
        mapping :mode, 'pg'

        mapping :notify_url, 'notify_url'
        mapping :return_url, ['surl', 'furl']
        mapping :cancel_return_url, 'curl'
        mapping :checksum, 'hash'

        mapping :user_defined, { :var1 => 'udf1',
          :var2 => 'udf2',
          :var3 => 'udf3',
          :var4 => 'udf4',
          :var5 => 'udf5',
          :var6 => 'udf6',
          :var7 => 'udf7',
          :var8 => 'udf8',
          :var9 => 'udf9',
          :var10 => 'udf10'
        }

        def initialize(order, account, options = {})
          super
          @options = options
          self.pg = 'CC'
          add_field('udf5', application_id)
        end

        def form_fields
          sanitize_fields
          @fields.merge(mappings[:checksum] => generate_checksum)
        end

        def generate_checksum
          checksum_payload_items = CHECKSUM_FIELDS.map { |field| @fields[field] }

          PayuIn.checksum(@fields["key"], @options[:credential2], checksum_payload_items )
        end

        def sanitize_fields
          @fields['phone'] = @fields['phone'].gsub(/[^0-9]/, '') if @fields['phone']
          ['address1', 'address2', 'city', 'state', 'country', 'productinfo', 'email'].each do |field|
            @fields[field] = @fields[field].gsub(/[^a-zA-Z0-9\-_@\/\s.]/, '') if @fields[field]
          end
        end

      end

      class Notification < OffsitePayments::Notification
        def initialize(post, options = {})
          super(post, options)
          @merchant_id = options[:credential1]
          @secret_key = options[:credential2]
        end

        def complete?
          status == "Completed"
        end

        def status
          case transaction_status.downcase
          when 'success' then 'Completed'
          when 'failure' then 'Failed'
          when 'pending' then 'Pending'
          end
        end

        def invoice_ok?( order_id )
          order_id.to_s == invoice.to_s
        end

        # Order amount should be equal to gross - discount
        def amount_ok?( order_amount, order_discount = BigDecimal.new( '0.0' ) )
          parsed_discount = discount.nil? ? 0.to_d : discount.to_d
          BigDecimal.new( original_gross ) == order_amount && parsed_discount == order_discount
        end

        # Status of transaction return from the PayU. List of possible values:
        # <tt>SUCCESS</tt>::
        # <tt>PENDING</tt>::
        # <tt>FAILURE</tt>::
        def transaction_status
          params['status']
        end

        # ID of this transaction (PayU.in number)
        def transaction_id
          params['mihpayid']
        end

        # Mode of Payment
        #
        # 'CC' for credit-card
        # 'NB' for net-banking
        # 'CD' for cheque or DD
        # 'CO' for Cash Pickup
        def type
          params['mode']
        end

        # What currency have we been dealing with
        def currency
          'INR'
        end

        def item_id
          params['txnid']
        end

        # This is the invoice which you passed to PayU.in
        def invoice
          params['txnid']
        end

        # Merchant Id provided by the PayU.in
        def account
          params['key']
        end

        # original amount send by merchant
        def original_gross
          params['amount']
        end

        def gross
          parse_and_round_gross_amount(params['amount'])
        end

        # This is discount given to user - based on promotion set by merchants.
        def discount
          params['discount']
        end

        # Description offer for what PayU given the offer to user - based on promotion set by merchants.
        def offer_description
          params['offer']
        end

        # Information about the product as send by merchant
        def product_info
          params['productinfo']
        end

        # Email of the customer
        def customer_email
          params['email']
        end

        # Phone of the customer
        def customer_phone
          params['phone']
        end

        # Firstname of the customer
        def customer_first_name
          params['firstname']
        end

        # Lastname of the customer
        def customer_last_name
          params['lastname']
        end

        # Full address of the customer
        def customer_address
          { :address1 => params['address1'], :address2 => params['address2'],
            :city => params['city'], :state => params['state'],
            :country => params['country'], :zipcode => params['zipcode'] }
        end

        def user_defined
          @user_defined ||= 10.times.map { |i| params["udf#{i + 1}"] }
        end

        def checksum
          params['hash']
        end

        def message
          @message || params['error']
        end

        def acknowledge(authcode = nil)
          checksum_ok?
        end

        def checksum_ok?
          checksum_fields = [transaction_status, *user_defined.reverse, customer_email, customer_first_name, product_info, original_gross, invoice]

          unless Digest::SHA512.hexdigest([@secret_key, *checksum_fields, @merchant_id].join("|")) == checksum
            @message = 'Return checksum not matching the data provided'
            return false
          end
          true
        end

        private
        def parse_and_round_gross_amount(amount)
          rounded_amount = (amount.to_f * 100.0).round
          sprintf("%.2f", rounded_amount / 100.00)
        end
      end

      class Return < OffsitePayments::Return
        def initialize(query_string, options = {})
          super
          @notification = Notification.new(query_string, options)
        end

        def transaction_id
          @notification.transaction_id
        end

        def status( order_id, order_amount )
          if @notification.invoice_ok?( order_id ) && @notification.amount_ok?( BigDecimal.new(order_amount) )
            @notification.status
          else
            'Mismatch'
          end
        end

        def success?
          status( @params['txnid'], @params['amount'] ) == 'Completed'
        end

        def message
          @notification.message
        end
      end
    end
  end
end
