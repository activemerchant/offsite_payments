module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    # USAGE:
    #
    # First define Maksuturva seller id and authcode in an initializer:
    #
    #   MAKSUTURVA_SELLERID = "testikauppias"
    #   MAKSUTURVA_AUTHCODE = "11223344556677889900"
    #
    # Then in view do something like this (use dynamic values for your app)
    #
    #   <% payment_service_for 2, MAKSUTURVA_SELLERID,
    #           :amount => "200,00", :currency => 'EUR', :credential2 => MAKSUTURVA_AUTHCODE,
    #           :service => :maksuturva do |service|
    #       service.pmt_reference = "134662"
    #       service.pmt_duedate = "24.06.2012"
    #       service.customer :phone => "0405051909",
    #           :email => "antti@example.com"
    #       service.billing_address :city => "Helsinki",
    #           :address1 => "Lorem street",
    #           :state => "-",
    #           :country => 'Finland',
    #           :zip => "00530"
    #       service.pmt_orderid = "2"
    #       service.pmt_buyername = "Antti Akonniemi"
    #       service.pmt_deliveryname = "Antti Akonniemi"
    #       service.pmt_deliveryaddress = "Köydenpunojankatu 13"
    #       service.pmt_deliverypostalcode = "00180"
    #       service.pmt_deliverycity = "Helsinki"
    #       service.pmt_deliverycountry = "FI"
    #       service.pmt_rows = 1
    #       service.pmt_row_name1 = "testi"
    #       service.pmt_row_desc1 = "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
    #       service.pmt_row_articlenr1 = "1"
    #       service.pmt_row_quantity1 = "1"
    #       service.pmt_row_deliverydate1 = "26.6.2012"
    #       service.pmt_row_price_gross1 = "200,00"
    #       service.pmt_row_vat1= "23,00"
    #       service.pmt_row_discountpercentage1 = "0,00"
    #       service.pmt_row_type1 = "1"
    #       service.pmt_charset = "UTF-8"
    #       service.pmt_charsethttp = "UTF-8"
    #
    #       service.return_url "http://localhost:3000/process"
    #       service.cancel_return_url "http://example.com"
    #       service.pmt_errorreturn "http://example.com"
    #
    #       service.pmt_delayedpayreturn "http://example.com"
    #       service.pmt_escrow "N"
    #       service.pmt_escrowchangeallowed "N"
    #       service.pmt_sellercosts "0,00"
    #       service.pmt_keygeneration "001"
    #        %>
    #
    # Then in the controller handle the return with something like this
    #
    #   def ipn
    #     notify = OffsitePayments::Integrations::Maksuturva::Notification.new(params)
    #
    #     if notify.acknowledge(MAKSUTURVA_AUTHCODE)
    #       # Process order
    #     else
    #       # Show error
    #     end
    #   end
    #
    # For full list of available parameters etc check the integration documents
    # here:
    #
    #   https://www.maksuturva.fi/services/vendor_services/integration_guidelines.html
    module Maksuturva
      mattr_accessor :service_url
      self.service_url = 'https://www.maksuturva.fi/NewPaymentExtended.pmt'

      def self.notification(post)
        Notification.new(post)
      end

      class Helper < OffsitePayments::Helper
        def initialize(order, account, options = {})
          md5secret options.delete(:credential2)
          super
          add_field("pmt_action", "NEW_PAYMENT_EXTENDED")
          add_field("pmt_version", "0004")
          add_field("pmt_sellerid", account)
          add_field("pmt_hashversion", "MD5")
        end

        def md5secret(value)
          @md5secret = value
        end

        def form_fields
          @fields.merge("pmt_hash" => generate_md5string)
        end

        def generate_md5string
          fields = [@fields["pmt_action"], @fields["pmt_version"]]
          fields += [@fields["pmt_selleriban"]] unless @fields["pmt_selleriban"].nil?
          fields += [@fields["pmt_id"], @fields["pmt_orderid"], @fields["pmt_reference"], @fields["pmt_duedate"],
          @fields["pmt_amount"], @fields["pmt_currency"], @fields["pmt_okreturn"], @fields["pmt_errorreturn"], @fields["pmt_cancelreturn"],
          @fields["pmt_delayedpayreturn"], @fields["pmt_escrow"], @fields["pmt_escrowchangeallowed"]]

          fields += [@fields["pmt_invoicefromseller"]] unless @fields["pmt_invoicefromseller"].nil?
          fields += [@fields["pmt_paymentmethod"]] unless @fields["pmt_paymentmethod"].nil?
          fields += [@fields["pmt_buyeridentificationcode"]] unless @fields["pmt_buyeridentificationcode"].nil?


          fields += [@fields["pmt_buyername"], @fields["pmt_buyeraddress"], @fields["pmt_buyerpostalcode"], @fields["pmt_buyercity"],
          @fields["pmt_buyercountry"], @fields["pmt_deliveryname"], @fields["pmt_deliveryaddress"], @fields["pmt_deliverypostalcode"], @fields["pmt_deliverycity"],
          @fields["pmt_deliverycountry"], @fields["pmt_sellercosts"]]

          (1..@fields["pmt_rows"].to_i).each do |i|
            fields += [@fields["pmt_row_name#{i}"], @fields["pmt_row_desc#{i}"], @fields["pmt_row_quantity#{i}"]]
            fields += [@fields["pmt_row_articlenr#{i}"]] unless @fields["pmt_row_articlenr#{i}"].nil?
            fields += [@fields["pmt_row_unit#{i}"]] unless @fields["pmt_row_unit#{i}"].nil?
            fields += [@fields["pmt_row_deliverydate#{i}"]]
            fields += [@fields["pmt_row_price_gross#{i}"]] unless @fields["pmt_row_price_gross#{i}"].nil?
            fields += [@fields["pmt_row_price_net#{i}"]] unless @fields["pmt_row_price_net#{i}"].nil?
            fields += [@fields["pmt_row_vat#{i}"], @fields["pmt_row_discountpercentage#{i}"], @fields["pmt_row_type#{i}"]]
          end
          fields += [@md5secret]
          fields = fields.join("&") + "&"
          Digest::MD5.hexdigest(fields).upcase
        end

        mapping :pmt_selleriban, "pmt_selleriban"
        mapping :pmt_reference, "pmt_reference"
        mapping :pmt_duedate, "pmt_duedate"
        mapping :pmt_userlocale, "pmt_userlocale"
        mapping :pmt_escrow, "pmt_escrow"
        mapping :pmt_escrowchangeallowed, "pmt_escrowchangeallowed"
        mapping :pmt_invoicefromseller, "pmt_invoicefromseller"
        mapping :pmt_paymentmethod, "pmt_paymentmethod"
        mapping :pmt_buyeridentificationcode, "pmt_buyeridentificationcode"
        mapping :pmt_buyername, "pmt_buyername"

        mapping :account, ''
        mapping :currency, 'pmt_currency'
        mapping :amount, 'pmt_amount'

        mapping :order, 'pmt_id'
        mapping :pmt_orderid, 'pmt_orderid'
        mapping :pmt_deliveryname, "pmt_deliveryname"
        mapping :pmt_deliveryaddress, "pmt_deliveryaddress"
        mapping :pmt_deliverypostalcode, "pmt_deliverypostalcode"
        mapping :pmt_deliverycity, "pmt_deliverycity"
        mapping :pmt_deliverycountry, "pmt_deliverycountry"
        mapping :pmt_sellercosts, "pmt_sellercosts"
        mapping :pmt_rows, "pmt_rows"

        (1..499.to_i).each do |i|
          mapping "pmt_row_name#{i}".to_sym, "pmt_row_name#{i}"
          mapping "pmt_row_desc#{i}".to_sym, "pmt_row_desc#{i}"
          mapping "pmt_row_quantity#{i}".to_sym, "pmt_row_quantity#{i}"
          mapping "pmt_row_articlenr#{i}".to_sym, "pmt_row_articlenr#{i}"
          mapping "pmt_row_unit#{i}".to_sym, "pmt_row_unit#{i}"
          mapping "pmt_row_deliverydate#{i}".to_sym, "pmt_row_deliverydate#{i}"
          mapping "pmt_row_price_gross#{i}".to_sym, "pmt_row_price_gross#{i}"
          mapping "pmt_row_price_net#{i}".to_sym, "pmt_row_price_net#{i}"
          mapping "pmt_row_vat#{i}".to_sym, "pmt_row_vat#{i}"
          mapping "pmt_row_discountpercentage#{i}".to_sym, "pmt_row_discountpercentage#{i}"
          mapping "pmt_row_type#{i}".to_sym, "pmt_row_type#{i}"
        end

        mapping :pmt_charset, "pmt_charset"
        mapping :pmt_charsethttp, "pmt_charsethttp"
        mapping :pmt_hashversion, "pmt_hashversion"
        mapping :pmt_keygeneration, "pmt_keygeneration"
        mapping :customer, :email      => 'pmt_buyeremail',
                           :phone      => 'pmt_buyerphone'

        mapping :billing_address, :city     => 'pmt_buyercity',
                                  :address1 => "pmt_buyeraddress",
                                  :address2 => '',
                                  :state    => '',
                                  :zip      => "pmt_buyerpostalcode",
                                  :country  => 'pmt_buyercountry'

        mapping :notify_url, ''
        mapping :return_url, 'pmt_okreturn'
        mapping :pmt_errorreturn, 'pmt_errorreturn'
        mapping :pmt_delayedpayreturn, 'pmt_delayedpayreturn'
        mapping :cancel_return_url, 'pmt_cancelreturn'

        mapping :description, ''
        mapping :tax, ''
        mapping :shipping, ''
      end

      class Notification < OffsitePayments::Notification
        def complete?
          true
        end

        def transaction_id
          params["pmt_id"]
        end

        def security_key
          params["pmt_hash"]
        end

        def gross
          params["pmt_amount"]
        end

        def currency
          params["pmt_currency"]
        end

        def status
          "PAID"
        end

        def acknowledge(authcode = nil)
          return_authcode = [params["pmt_action"], params["pmt_version"], params["pmt_id"], params["pmt_reference"], params["pmt_amount"], params["pmt_currency"], params["pmt_sellercosts"], params["pmt_paymentmethod"], params["pmt_escrow"], authcode].join("&")
          (Digest::MD5.hexdigest(return_authcode + "&").upcase == params["pmt_hash"])
        end

        private

        def parse(post)
          post.each do |key, value|
            params[key] = value
          end
        end
      end
    end
  end
end
