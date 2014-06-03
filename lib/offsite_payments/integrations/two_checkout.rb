module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module TwoCheckout
      mattr_accessor :payment_routine
      self.payment_routine = :single_page

      def self.service_url
        case self.payment_routine
        when :multi_page
          'https://www.2checkout.com/checkout/purchase'
        when :single_page
          'https://www.2checkout.com/checkout/spurchase'
        else
          raise StandardError, "Integration payment routine set to an invalid value: #{self.payment_routine}"
        end
      end

      def self.service_url=(service_url)
        # Note: do not use this method, it is here for backward compatibility
        # Use the payment_routine method to change service_url
        if service_url =~ /spurchase/
          self.payment_routine = :single_page
        else
          self.payment_routine = :multi_page
        end
      end

      def self.notification(post, options = {})
        Notification.new(post, options)
      end

      def self.return(query_string, options = {})
        Return.new(query_string, options)
      end

      class Helper < OffsitePayments::Helper
        def initialize(order, account, options = {})
          super
          if OffsitePayments.mode == :test || options[:test]
            add_field('demo', 'Y')
          end
        end

        # The 2checkout vendor account number
        mapping :account, 'sid'

        # The total amount to be billed, in decimal form, without a currency symbol. (8 characters, decimal, 2 characters: Example: 99999999.99)
        # This field is only used with the Third Party Cart parameter set.
        mapping :amount, 'total'

        # Pass the sale's currency code.
        mapping :currency, 'currency_code'

        # Pass your order id.  (50 characters max)
        mapping :order, 'merchant_order_id'

        # Pass your cart identifier if you are using Third Part Cart Parameters. (128 characters max)
        # This value is visible to the buyer and will be listed as the sale's lineitem.
        mapping :invoice, 'cart_order_id'

        mapping :customer,
                :email      => 'email',
                :phone      => 'phone'

        mapping :billing_address,
                :city     => 'city',
                :address1 => 'street_address',
                :address2 => 'street_address2',
                :state    => 'state',
                :zip      => 'zip',
                :country  => 'country'

        mapping :shipping_address,
                :name     => 'ship_name',
                :city     => 'ship_city',
                :address1 => 'ship_street_address',
                :address2 => 'ship_street_address2',
                :state    => 'ship_state',
                :zip      => 'ship_zip',
                :country  => 'ship_country'

        # Overrides Approved URL for return process redirects
        mapping :return_url, 'x_receipt_link_url'

        # notifications are sent via static URLs in the Instant Notification Settings of 2Checkout admin
        mapping :notify_url, 'notify_url'

        # Allow seller to indicate the step of the checkout page
        # Possible values: ‘review-cart’, ‘shipping-information’, ‘shipping-method’, ‘billing-information’ and ‘payment-method’
        mapping :purchase_step, 'purchase_step'

        # Allow referral partners to indicate their shopping cart
        mapping :cart_type, '2co_cart_type'

        def customer(params = {})
          add_field(mappings[:customer][:email], params[:email])
          add_field(mappings[:customer][:phone], params[:phone])
          add_field('card_holder_name', "#{params[:first_name]} #{params[:last_name]}")
        end

        def shipping_address(params = {})
          super
          add_field(mappings[:shipping_address][:name], "#{params[:first_name]} #{params[:last_name]}")
        end

        # Uses Third Party Cart parameter set to pass in lineitem details.
        # You must also specify `service.invoice` when using this method.
        def third_party_cart(params = {})
          add_field('id_type', '1')
          (max_existing_line_item_id = form_fields.keys.map do |key|
            i = key.to_s[/^c_prod_(\d+)/, 1]
            (i && i.to_i)
          end.compact.max || 0)

          line_item_id = max_existing_line_item_id + 1
          params.each do |key, value|
            add_field("c_#{key}_#{line_item_id}", value)
          end
        end
      end

      class Notification < OffsitePayments::Notification
        # message_type - Indicates type of message
        # message_description - Human readable description of message_type
        # timestamp - Timestamp of event; format YYYY-MM-DD HH:MM:SS ZZZ
        # md5_hash - UPPERCASE(MD5_ENCRYPTED(sale_id + vendor_id + invoice_id + Secret Word))
        # message_id - This number is incremented for each message sent to a given seller.
        # key_count - Indicates the number of parameters sent in message
        # vendor_id - Seller account number
        # sale_id - 2Checkout sale number
        # sale_date_placed - Date of sale; format YYYY-MM-DD
        # vendor_order_id - Custom order id provided by seller, if available.
        # invoice_id - 2Checkout invoice number; Each recurring sale can have several invoices
        # recurring - recurring=1 if any item on the invoice is a recurring item, 0 otherwise
        # payment_type - Buyer’s payment method (credit card, online check, paypal ec, OR paypal pay later)
        # list_currency - 3-Letter ISO code for seller currency
        # cust_currency - 3-Letter ISO code for buyer currency
        # auth_exp - The date credit authorization will expire; format YYYY-MM-DD
        # invoice_status - Status of a transaction (approved, pending, deposited, or declined)
        # fraud_status - Status of 2Checkout fraud review (pass, fail, or wait); This parameter could be empty.
        # invoice_list_amount - Total in seller pricing currency; format as appropriate to currency=
        # invoice_usd_amount - Total in US Dollars; format with 2 decimal places
        # invoice_cust_amount - Total in buyer currency; format as appropriate to currency=
        # customer_first_name - Buyer’s first name (may not be available on older sales)
        # customer_last_name - Buyer’s last name (may not be available on older sales)
        # customer_name - Buyer's full name (name as it appears on credit card)
        # customer_email - Buyer's email address
        # customer_phone - Buyer's phone number; all but digits stripped out
        # customer_ip - Buyer's IP address at time of sale
        # customer_ip_country - Country of record for buyer's IP address at time of sale
        # bill_street_address - Billing street address
        # bill_street_address2 - Billing street address line 2
        # bill_city - Billing address city
        # bill_state - Billing address state or province
        # bill_postal_code - Billing address postal code
        # bill_country - 3-Letter ISO country code of billing address
        # ship_status - not_shipped, shipped, or empty (if intangible / does not need shipped)
        # ship_tracking_number - Tracking Number as entered in Seller Admin
        # ship_name - Shipping Recipient’s name (as it should appears on shipping label)
        # ship_street_address - Shipping street address
        # ship_street_address2 - Shipping street address line 2
        # ship_city - Shipping address city
        # ship_state - Shipping address state or province
        # ship_postal_code - Shipping address postal code
        # ship_country - 3-Letter ISO country code of shipping address
        # item_count - Indicates how many numbered sets of item parameters to expect
        # item_name_# - Product name
        # item_id_# - Seller product id
        # item_list_amount_# - Total in seller pricing currency; format as appropriate to currency
        # item_usd_amount_# - Total in US Dollars; format with 2 decimal places
        # item_cust_amount_# - Total in buyer currency; format as appropriate to currency
        # item_type_# - Indicates if item is a bill or refund; Value will be bill or refund
        # item_duration_# - Product duration, how long it re-bills for Ex. 1 Year
        # item_recurrence_# - Product recurrence, how often it re-bills Ex. 1 Month
        # item_rec_list_amount_# - Product price; format as appropriate to currency
        # item_rec_status_# - Indicates status of recurring subscription: live, canceled, or completed
        # item_rec_date_next_# - Date of next recurring installment; format YYYY-MM-DD
        # item_rec_install_billed_# - The number of successful recurring installments successfully billed

        # INS message type
        def type
          params['message_type']
        end

        # Seller currency sale was placed in
        def currency
          params['list_currency']
        end

        def complete?
          status == 'Completed'
        end

        # The value passed with 'merchant_order_id' is passed back as 'vendor_order_id'
        def item_id
          params['vendor_order_id'] || params['merchant_order_id']
        end

        # 2Checkout Sale ID
        def transaction_id
          params['sale_id'] || params['order_number']
        end

        # 2Checkout Invoice ID
        def invoice_id
          params['invoice_id']
        end

        def received_at
          params['timestamp']
        end

        #Customer Email
        def payer_email
          params['customer_email']
        end

        # The MD5 Hash
        def security_key
          params['md5_hash'] || params['key']
        end

        # The money amount we received in X.2 decimal.
        # passback || INS gross amount for new orders || default INS gross
        def gross
          params['invoice_list_amount'] || params['total'] || params['item_list_amount_1']
        end

        # Determine status based on parameter set, if the params include a fraud status we know we're being
        # notified of the finalization of an order (an INS message)
        # If the params include 'credit_card_processed' we know we're being notified of a new order being inbound,
        # which we handle in the deferred demo sale scenario.
        def status
          if params['fraud_status'] == 'pass' || params['credit_card_processed'] == 'Y'
            'Completed'
          elsif params['fraud_status'] == 'wait'
            'Pending'
          else
            'Failed'
          end
        end

        # Secret Word defined in 2Checkout account
        def secret
          @options[:credential2]
        end

        # Checks against MD5 Hash
        def acknowledge(authcode = nil)
          return false if security_key.blank?
          if ins_message?
            Digest::MD5.hexdigest("#{ transaction_id }#{ params['vendor_id'] }#{ invoice_id }#{ secret }").upcase == security_key.upcase
          elsif passback?
            order_number = params['demo'] == 'Y' ? 1 : params['order_number']
            Digest::MD5.hexdigest("#{ secret }#{ params['sid'] }#{ order_number }#{ gross }").upcase == params['key'].upcase
          else
            false
          end
        end

        private

        # Parses Header Redirect Query String
        def parse(post)
          @raw = post.to_s
          for line in @raw.split('&')
            key, value = *line.scan( %r{^(\w+)\=(.*)$} ).flatten
            params[key] = CGI.unescape(value || '')
          end
        end

        def ins_message?
          params.include? 'message_type'
        end

        def passback?
          params.include? 'credit_card_processed'
        end
      end

      class Return < OffsitePayments::Return
        # card_holder_name - Provides the customer’s name.
        # city - Provides the customer’s city.
        # country - Provides the customer’s country.
        # credit_card_processed - This parameter will always be passed back as Y.
        # demo - Defines if an order was live, or if the order was a demo order. If the order was a demo, the MD5 hash will fail.
        # email - Provides the email address the customer provided when placing the order.
        # fixed - This parameter will only be passed back if it was passed into the purchase routine.
        # ip_country - Provides the customer’s IP location.
        # key - An MD5 hash used to confirm the validity of a sale.
        # lang - Customer language
        # merchant_order_id - The order ID you had assigned to the order.
        # order_number - The 2Checkout order number associated with the order.
        # invoice_id - The 2Checkout invoice number.
        # pay_method - Provides seller with the customer’s payment method. CC for Credit Card, PPI for PayPal.
        # phone - Provides the phone number the customer provided when placing the order.
        # ship_name - Provides the ship to name for the order.
        # ship_street_address - Provides ship to address.
        # ship_street_address2 - Provides more detailed shipping address if this information was provided by the customer.
        # ship_city - Provides ship to city.
        # ship_state - Provides ship to state.
        # ship_zip - Ship Zip

        # Pass Through Products Only
        # li_#_name - Name of the corresponding lineitem.
        # li_#_quantity - Quantity of the corresponding lineitem.
        # li_#_price - Price of the corresponding lineitem.
        # li_#_tangible - Specifies if the corresponding li_#_type is a tangible or intangible. ‘Y’ OR ‘N’
        # li_#_product_id - ID of the corresponding lineitem.
        # li_#_product_description - Description of the corresponding lineitem.
        # li_#_recurrence - # WEEK | MONTH | YEAR – always singular.
        # li_#_duration - Forever or # WEEK | MONTH | YEAR – always singular, defaults to Forever.
        # li_#_startup_fee - Amount in account pricing currency.
        # li_#_option_#_name - Name of option. 64 characters max – cannot include '<' or '>'.
        # li_#_option_#_value - Name of option. 64 characters max – cannot include '<' or '>'.
        # li_#_option_#_surcharge - Amount in account pricing currency.

        #Third Party Cart Only
        # cart_order_id - The order ID you had assigned to the order

        def initialize(query_string, options = {})
          super
          @notification = Notification.new(query_string, options)
        end

        def success?
          @notification.status != 'Failed'
        end
      end
    end
  end
end
