module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module AuthorizeNetSim
      # Overwrite this if you want to change the ANS test url
      mattr_accessor :test_url
      self.test_url = 'https://test.authorize.net/gateway/transact.dll'

      # Overwrite this if you want to change the ANS production url
      mattr_accessor :production_url
      self.production_url = 'https://secure.authorize.net/gateway/transact.dll'

      def self.service_url
        mode = OffsitePayments.mode
        case mode
        when :production
          self.production_url
        when :test
          self.test_url
        else
          raise StandardError, "Integration mode set to an invalid value: #{mode}"
        end
      end

      def self.notification(post)
        Notification.new(post)
      end

      def self.return(query_string)
        Return.new(query_string)
      end

      # An example. Note the username as a parameter and transaction key you
      # will want to use later. The amount that you pass in will be *rounded*,
      # so preferably pass in X.2 decimal so that no rounding occurs. It is
      # rounded because if it looks like 00.000 Authorize.Net fails the
      # transaction as incorrectly formatted.
      #
      #  payment_service_for('order_id', 'authorize_net_account', :service => :authorize_net_sim,  :amount => 157.0) do |service|
      #
      #    # You must call setup_hash and invoice
      #
      #    service.setup_hash :transaction_key => '8CP6zJ7uD875J6tY',
      #        :order_timestamp => 1206836763
      #    service.customer_id 8
      #    service.customer :first_name => 'g',
      #                       :last_name => 'g',
      #                       :email => 'g@g.com',
      #                       :phone => '3'
      #   service.billing_address :zip => 'g',
      #                   :country => 'United States of America',
      #                   :address => 'g'
      #
      #   service.ship_to_address :first_name => 'g',
      #                            :last_name => 'g',
      #                            :city => '',
      #                            :address => 'g',
      #                            :address2 => '',
      #                            :state => address.state,
      #                            :country => 'United States of America',
      #                            :zip => 'g'
      #
      #   service.invoice "516428355" # your invoice number
      #   # The end-user is presented with the HTML produced by the notify_url.
      #   service.notify_url "http://t/authorize_net_sim/payment_received_notification_sub_step"
      #   service.payment_header 'My store name'
      #   service.add_line_item :name => 'item name', :quantity => 1, :unit_price => 0
      #   service.test_request 'true' # only if it's just a test
      #   service.shipping '25.0'
      #   # Tell it to display a "0" line item for shipping, with the price in
      #   # the name, otherwise it isn't shown at all, leaving the end user to
      #   # wonder why the total is different than the sum of the line items.
      #   service.add_shipping_as_line_item
      #   server.add_tax_as_line_item # same with tax
      #   # See the helper.rb file for various custom fields
      # end

      class Helper < OffsitePayments::Helper
        mapping :order, 'x_fp_sequence'
        mapping :account, 'x_login'

        mapping :customer, :first_name => 'x_first_name',
                           :last_name  => 'x_last_name',
                           :email      => 'x_email',
                           :phone      => 'x_phone'

        mapping :notify_url, 'x_relay_url'
        mapping :return_url, '' # unused
        mapping :cancel_return_url, '' # unused

        # Custom fields for Authorize.net SIM.
        # See http://www.Authorize.Net/support/SIM_guide.pdf for more descriptions.
        mapping :fax, 'x_fax'
        mapping :customer_id, 'x_cust_id'
        mapping :description, 'x_description'
        mapping :tax, 'x_tax'
        mapping :shipping, 'x_freight'

        # True or false, or 0 or 1 same effect [not required to send one,
        # defaults to false].
        mapping :test_request, 'x_test_request'

        # This one is necessary for the notify url to be able to parse its
        # information later! They also pass back customer id, if that's
        # useful.
        def invoice(number)
          add_field 'x_invoice_num', number
        end

        # Set the billing address. Call like service.billing_address {:city =>
        # 'provo, :state => 'UT'}...
        def billing_address(options)
          for setting in [:city, :state, :zip, :country, :po_num] do
            add_field 'x_' + setting.to_s, options[setting]
          end
          raise 'must use address1 and address2' if options[:address]
          add_field 'x_address', (options[:address1].to_s + ' ' + options[:address2].to_s).strip
        end

        # Adds a custom field which you submit to Authorize.Net. These fields
        # are all passed back to you verbatim when it does its relay
        # (callback) to you note that if you call it twice with the same name,
        # this function only uses keeps the second value you called it with.
        def add_custom_field(name, value)
          add_field name, value
        end

        # Displays tax as a line item, so they can see it. Otherwise it isn't
        # displayed.
        def add_tax_as_line_item
          raise unless @fields['x_tax']
          add_line_item :name => 'Total Tax', :quantity => 1, :unit_price => @fields['x_tax'], :tax => 0, :line_title => 'Tax'
        end

        # Displays shipping as a line item, so they can see it. Otherwise it
        # isn't displayed.
        def add_shipping_as_line_item(extra_options = {})
          raise 'must set shipping/freight before calling this' unless @fields['x_freight']
          add_line_item extra_options.merge({:name => 'Shipping and Handling Cost', :quantity => 1, :unit_price => @fields['x_freight'], :line_title => 'Shipping'})
        end

        # Add ship_to_address in the same format as the normal address is
        # added.
        def ship_to_address(options)
          for setting in [:first_name, :last_name, :company, :city, :state, :zip, :country] do
            if options[setting] then
              add_field 'x_ship_to_' + setting.to_s, options[setting]
            end
          end
          raise 'must use :address1 and/or :address2' if options[:address]
          add_field 'x_ship_to_address', (options[:address1].to_s + ' ' + options[:address2].to_s).strip
        end

        # These control the look of the SIM payment page. Note that you can
        # include a CSS header in descriptors, etc.
        mapping :color_link, 'x_color_link'
        mapping :color_text, 'x_color_text'
        mapping :logo_url, 'x_logo_url'
        mapping :background_url, 'x_background_url' # background image url for the page
        mapping :payment_header, 'x_header_html_payment_form'
        mapping :payment_footer, 'x_footer_html_payment_form'

        # For this to work you must have also passed in an email for the
        # purchaser.
        def yes_email_customer_from_authorizes_side
          add_field 'x_email_customer', 'TRUE'
        end

        # Add a line item to Authorize.Net.
        # Call line add_line_item {:name => 'orange', :unit_price => 30, :tax_value => 'Y', :quantity => 3, }
        # Note you can't pass in a negative unit price, and you can add an
        # optional :line_title => 'special name' if you don't want it to say
        # 'Item 1' or what not, the default coded here.
        # Cannot have a negative price, nor a name with "'s or $
        # You can use the :line_title for the product name and then :name for description, if desired
        def add_line_item(options)
          raise 'needs name' unless options[:name]

          if @line_item_count == 30
            # Add a note that we are not showing at least one -- AN doesn't
            # display more than 30 or so.
            description_of_last = @raw_html_fields[-1][1]
            # Pull off the second to last section, which is the description.
            description_of_last =~ />([^>]*)<\|>[YN]$/
            # Create a new description, which can't be too big, so truncate here.
            @raw_html_fields[-1][1] = description_of_last.gsub($1, $1[0..200] + ' + more unshown items after this one.')
          end

          name = options[:name]
          quantity = options[:quantity] || 1
          line_title = options[:line_title] || ('Item ' + (@line_item_count + 1).to_s) # left most field
          unit_price = options[:unit_price] || 0
          unit_price = unit_price.to_f.round(2)
          tax_value = options[:tax_value] || 'N'

          # Sanitization, in case they include a reserved word here, following
          # their guidelines; unfortunately, they require 'raw' fields here,
          # not CGI escaped, using their own delimiters.
          #
          # Authorize.net ignores the second field (sanitized_short_name)
          raise 'illegal char for line item <|>' if name.include? '<|>'
          raise 'illegal char for line item "' if name.include? '"'
          raise 'cannot pass in dollar sign' if unit_price.to_s.include? '$'
          raise 'must have positive or 0 unit price' if unit_price.to_f < 0
          # Using CGI::escape causes the output to be formated incorrectly in
          # the HTML presented to the end-user's browser (e.g., spaces turn
          # into +'s).
          sanitized_short_name = name[0..30]
          name = name[0..255]

          add_raw_html_field "x_line_item", "#{line_title}<|>#{sanitized_short_name}<|>#{name}<|>#{quantity}<|>#{unit_price}<|>#{tax_value}"

          @line_item_count += 1
        end

        # If you call this it will e-mail to this address a copy of a receipt
        # after successful, from Authorize.Net.
        def email_merchant_from_authorizes_side(to_this_email)
          add_field 'x_email_merchant', to_this_email
        end

        # You MUST call this at some point for it to actually work. Options
        # must include :transaction_key and :order_timestamp
        def setup_hash(options)
          raise unless options[:transaction_key]
          raise unless options[:order_timestamp]
          amount = @fields['x_amount']
          data = "#{@fields['x_login']}^#{@fields['x_fp_sequence']}^#{options[:order_timestamp].to_i}^#{amount}^#{@fields['x_currency_code']}"
          hmac = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('md5'), options[:transaction_key], data)
          add_field 'x_fp_hash', hmac
          add_field 'x_fp_timestamp', options[:order_timestamp].to_i
        end

        # Note that you should call #invoice and #setup_hash as well, for the
        # response_url to actually work.
        def initialize(order, account, options = {})
          super
          raise 'missing parameter' unless order and account and options[:amount]
          raise 'error -- amount with no digits!' unless options[:amount].to_s =~ /\d/
          add_field('x_type', 'AUTH_CAPTURE') # the only one we deal with, for now.  Not refunds or anything else, currently.
          add_field 'x_show_form', 'PAYMENT_FORM'
          add_field 'x_relay_response', 'TRUE'
          add_field 'x_duplicate_window', '28800' # large default duplicate window.
          add_field 'x_currency_code', currency_code
          add_field 'x_version' , '3.1' # version from doc
          add_field 'x_amount', options[:amount].to_f.round(2)
          @line_item_count = 0
        end
      end

      # # Example:
      # parser = AuthorizeNetSim::Notification.new(request.raw_post)
      # passed = parser.complete?
      #
      # order = Order.find_by_order_number(parser.invoice_num)
      #
      # unless order
      #   @message = 'Error--unable to find your transaction! Please contact us directly.'
      #   return render :partial => 'authorize_net_sim_payment_response'
      # end
      #
      # if order.total != parser.gross.to_f
      #   logger.error "Authorize.Net sim said they paid for #{parser.gross} and it should have been #{order.total}!"
      #   passed = false
      # end
      #
      # # Theoretically, Authorize.net will *never* pass us the same transaction
      # # ID twice, but we can double check that... by using
      # # parser.transaction_id, and checking against previous orders' transaction
      # # id's (which you can save when the order is completed)....
      # unless parser.acknowledge MD5_HASH_SET_IN_AUTHORIZE_NET, AUTHORIZE_LOGIN
      #  passed = false
      #  logger.error "ALERT POSSIBLE FRAUD ATTEMPT either that or you haven't setup your md5 hash setting right in #{__FILE__}
      #    because a transaction came back from Authorize.Net with the wrong hash value--rejecting!"
      # end
      #
      # unless parser.cavv_matches? and parser.avs_code_matches?
      #   logger.error 'Warning--non matching CC!' + params.inspect
      #   # Could fail them here, as well (recommended)...
      # end
      #
      # if passed
      #  # Set up your session, and render something that will redirect them to
      #  # your site, most likely.
      # else
      #  # Render failure or redirect them to your site where you will render failure
      # end
      class Notification < OffsitePayments::Notification

        def unescape(val) #:nodoc:
          if val
            CGI::unescape val
          else
            val
          end
        end

        # Passes a hash of the address the user entered in at Authorize.Net
        def billing_address
          all = {}
          [:fax, :city, :company, :last_name, :country, :zip, :first_name, :address, :email, :state].each do |key_out|
            all[key_out] = unescape params['x_' + key_out.to_s]
          end
          all
        end

        def customer_id
          unescape params['x_cust_id']
        end

        def auth_code
          unescape params['x_auth_code']
        end

        def po_num
         unescape params['x_po_num']
        end

        def ship_to_address
         all = {}
          [:city, :last_name, :first_name, :country, :zip, :address].each do |key_out|
            all[key_out] = unescape params['x_ship_to_' + key_out.to_s]
          end
          all
        end

        # Tax amount we sent them.
        def tax
          unescape params['x_tax']
        end

        # Transaction type (probably going to be auth_capture, since that's
        # all we set it as).
        def transaction_type
          unescape params['x_type']
        end

        # Payment method used--almost always CC (for credit card).
        def method
          unescape params['x_method']
        end

        # Ff our payment method is available. Almost always "true".
        def method_available
          params['x_method_available']
        end

        # Invoice num we passed in as invoice_num to them.
        def invoice_num
          item_id
        end

        # If you pass any values to authorize that aren't its expected, it
        # will pass them back to you verbatim, returned by this method.
        # custom values:
        def all_custom_values_passed_in_and_now_passed_back_to_us
          all = {}
          params.each do |key, value|
            if key[0..1] != 'x_'
              all[key] = unescape value
            end
          end
          all
        end

        def duty
          unescape params['x_duty']
        end

        # Shipping we sent them.
        def freight
          unescape params['x_freight']
        end
        alias_method :shipping, :freight

        def description
          unescape params['x_description']
        end

        # Returns the response code as a symbol.
        # {'1' => :approved, '2' => :declined, '3' => :error, '4' => :held_for_review}
        def response_code_as_ruby_symbol
          map = {'1' => :approved, '2' => :declined, '3' => :error, '4' => :held_for_review}
          map[params['x_response_code']]
        end

        def response_reason_text
          unescape params['x_response_reason_text']
        end

        # The response reason text's numeric id [equivalent--just a number]
        def response_reason_code
          unescape params['x_response_reason_code']
        end

        # 'used internally by their gateway'
        def response_subcode
          params['x_response_subcode']
        end

        # They pass back a tax_exempt value.
        def tax_exempt
          params['x_tax_exempt']
        end

        # avs [address verification] code
        # A = Address (Street)
        # matches, ZIP does not
        # B = Address information
        # not provided for AVS
        # check
        # E = AVS error
        # G = Non-U.S. Card Issuing
        # Bank
        # N = No Match on Address
        # (Street) or ZIP
        # P = AVS not applicable for
        # this transaction
        # R = Retry – System
        # unavailable or timed out
        # S = Service not supported
        # by issuer
        # U = Address information is
        # unavailable
        # W = Nine digit ZIP
        # matches, Address (Street)
        # does not
        # X = Address (Street) and
        # nine digit ZIP match
        # Y = Address (Street) and
        # five digit ZIP match
        # Z = Five digit ZIP matches
        # Address (Street) does not
        def avs_code
          params['x_avs_code']
        end

        # Returns true if their address completely matched [Y or X, P from
        # #avs_code, which mean 'add+zip match', 'address + 9-zip match', and
        # not applicable, respectively].
        def avs_code_matches?
          return ['Y', 'X', 'P'].include? params['x_avs_code']
        end

        # cvv2 response
        # M = Match
        # N = No Match
        # P = Not Processed
        # S = Should have been
        # present
        # U = Issuer unable to
        # process request
        def cvv2_resp_code
          params['x_cvv2_resp_code']
        end

        # check if #cvv2_resp_code == 'm' for Match.  otherwise false
        def cvv2_resp_code_matches?
          return ['M'].include? cvv2_resp_code
        end

        # cavv_response--'cardholder authentication verification response code'--most likely not use for SIM
        # Blank or not present  =
        # CAVV not validated
        # 0 = CAVV not validated
        # because erroneous data
        # was submitted
        # 1 = CAVV failed validation
        # 2 = CAVV passed
        # validation
        # 3 = CAVV validation could
        # not be performed; issuer
        # attempt incomplete
        # 4 = CAVV validation could
        # not be performed; issuer
        # system error
        # 5 = Reserved for future
        # use
        # 6 = Reserved for future
        # use
        # 7 = CAVV attempt – failed
        # validation – issuer
        # available (U.S.-issued
        # card/non-U.S acquirer)
        # 8 = CAVV attempt –
        # passed validation – issuer
        # available (U.S.-issued
        # card/non-U.S. acquirer)
        # 9 = CAVV attempt – failed
        # validation – issuer
        def cavv_response
          params['x_cavv_response']
        end

        # Check if #cavv_response == '', '2', '8' one of those [non failing]
        # [blank means no validated, 2 is passed, 8 is passed issuer
        # available]
        def cavv_matches?
          ['','2','8'].include? cavv_response
        end

        # Payment is complete -- returns true if x_response_code == '1'
        def complete?
          params["x_response_code"] == '1'
        end

        # Alias for invoice number--this is the only id they pass back to us
        # that we passed to them, except customer id is also passed back.
        def item_id
          unescape params['x_invoice_num']
        end

        # They return this number to us [it's unique to Authorize.net].
        def transaction_id
          params['x_trans_id']
        end

        # When was this payment was received by the client. --unimplemented --
        # always returns nil
        def received_at
          nil
        end

        # End-user's email
        def payer_email
          unescape params['x_email']
        end

        # They don't pass merchant email back to us -- unimplemented -- always
        # returns nil
        def receiver_email
          nil
        end

        # md5 hash used internally
        def security_key
          params['x_MD5_Hash']
        end

        # The money amount we received in X.2 decimal. Returns a string
        def gross
          unescape params['x_amount']
        end

        # Was this a test transaction?
        def test?
          params['x_test_request'] == 'true'
        end

        # #method_available alias
        def status
          complete?
        end

        # Called to request back and check if it was a valid request.
        # Authorize.net passes us back a hash that includes a hash of our
        # 'unique' MD5 value that we set within their system.
        #
        # Example:
        # acknowledge('my secret md5 hash that I set within Authorize.Net', 'authorize_login')
        #
        # Note this is somewhat unsafe unless you actually set that md5 hash
        # to something (defaults to '' in their system).
        def acknowledge(md5_hash_set_in_authorize_net, authorize_net_login_name)
          Digest::MD5.hexdigest(md5_hash_set_in_authorize_net + authorize_net_login_name + params['x_trans_id'] + gross) == params['x_MD5_Hash'].downcase
        end

       private

        # Take the posted data and move the relevant data into a hash.
        def parse(post)
          @raw = post
          post.split('&').each do |line|
            key, value = *line.scan( %r{^(\w+)\=(.*)$} ).flatten
            params[key] = value
          end
        end
      end
    end
  end
end
