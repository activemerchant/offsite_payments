module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module FirstData
      # Overwrite this if you want to change the ANS test url
      mattr_accessor :test_url
      self.test_url = 'https://demo.globalgatewaye4.firstdata.com/payment'

      # Overwrite this if you want to change the ANS production url
      mattr_accessor :production_url
      self.production_url = 'https://checkout.globalgatewaye4.firstdata.com/payment'

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

      # First Data payment pages emulates the Authorize.Net SIM API. See
      # OffsitePayments::Integrations::AuthorizeNetSim::Helper for
      # more details.
      #
      # An example. Note the username as a parameter and transaction key you
      # will want to use later.
      #
      #  payment_service_for('order_id', 'first_data_payment_page_id', :service => :first_data,  :amount => 157.0) do |service|
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
      #   # The end-user is presented with the HTML produced by the notify_url
      #   # (using the First Data Receipt Link feature).
      #   service.return_url "http://mysite/first_data_receipt_generator_page"
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
      class Helper < OffsitePayments::Integrations::AuthorizeNetSim::Helper
        # Configure notify_url to use the "Relay Response" feature
        mapping :notify_url, 'x_relay_url'

        # Configure return_url to use the "Receipt Link" feature
        mapping :return_url, 'x_receipt_link_url'
      end

      # First Data payment pages emulates the Authorize.Net SIM API. See
      # OffsitePayments::Integrations::FirstData::Notification for
      # more details.
      #
      # # Example:
      # parser = FirstData::Notification.new(request.raw_post)
      # passed = parser.complete?
      #
      # order = Order.find_by_order_number(parser.invoice_num)
      #
      # unless order
      #   @message = 'Error--unable to find your transaction! Please contact us directly.'
      #   return render :partial => 'first_data_payment_response'
      # end
      #
      # if order.total != parser.gross.to_f
      #   logger.error "First Data said they paid for #{parser.gross} and it should have been #{order.total}!"
      #   passed = false
      # end
      #
      # # Theoretically, First Data will *never* pass us the same transaction
      # # ID twice, but we can double check that... by using
      # # parser.transaction_id, and checking against previous orders' transaction
      # # id's (which you can save when the order is completed)....
      # unless parser.acknowledge FIRST_DATA_TRANSACTION_KEY, FIRST_DATA_RESPONSE_KEY
      #  passed = false
      #  logger.error "ALERT POSSIBLE FRAUD ATTEMPT"
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
      class Notification < OffsitePayments::Integrations::AuthorizeNetSim::Notification
        def acknowledge(response_key, payment_page_id)
          Digest::MD5.hexdigest(response_key + payment_page_id + params['x_trans_id'] + sprintf('%.2f', gross)) == params['x_MD5_Hash'].downcase
        end
      end
    end
  end
end
