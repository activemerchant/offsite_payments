require 'builder'

module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module MPay24
      mattr_accessor :service_url
      self.service_url = 'https://test.mpay24.com'

      mattr_accessor :production_url
      self.production_url = 'https://www.mpay24.com/'

      def self.notification(post)
        Notification.new(post)
      end

      class Helper < OffsitePayments::Helper
        mapping :account, 'merchantID'
        mapping :amount, 'Price'
        mapping :order, 'Tid'

        mapping :customer, :email => 'Email',
                           :phone => 'Phone'

        mapping :billing_address, :city     => 'City',
                                  :address1 => 'Street',
                                  :address2 => 'Street2',
                                  :state    => 'State',
                                  :zip      => 'Zip',
                                  :country  => 'Country'

        mapping :notify_url, 'Confirmation'
        mapping :return_url, 'Success'
        mapping :cancel_return_url, 'Error'
        mapping :description, 'Description'
        mapping :tax, 'Tax'
        mapping :shipping, 'ShippingCosts'

        def initialize(order, account, options={})
          super
          @account = account
          @order = order 
        end

        def customer(params={})
          add_field 'Name', "#{params[:first_name]} #{params[:last_name]}"
          add_field mappings[:customer][:email], params[:email]
          add_field mappings[:customer][:phone], params[:phone]
        end

        def generate_request
          builder = Builder::XmlMarkup.new
          builder.instruct! :xml, :version=>"1.0", :encoding => "UTF-8"
          mdxi = builder.Order do |o|
            o.Tid @fields['Tid']
            o.ShoppingCart do |s|
              s.Item do |i|
                i.Description @fields['Description']
              end
              s.ShippingCosts @fields['ShippingCosts']
              s.Tax @fields['Tax']
            end
            o.Price @fields['Price']
            o.URL do |u|
              u.Success @fields['Success']
              u.Error @fields['Error']
              u.Confirmation @fields['Confirmation']
            end
          end
        end
      end

      class Notification < OffsitePayments::Notification
        def complete?
          status == 'BILLED'
        end

        def item_id
          params['']
        end

        def transaction_id
          params['TID']
        end

        # When was this payment received by the client.
        def received_at
          params['']
        end

        def payer_email
          params['CUSTOMER_EMAIL']
        end

        def receiver_email
          params['']
        end

        def security_key
          params['']
        end

        # the money amount we received in X.2 decimal.
        def gross
          params['']
        end

        # Was this a test transaction?
        def test?
          params['ORDERDESC'] == 'test'
        end

        def status
          params['STATUS']
        end

        # Acknowledge the transaction to MPay24. This method has to be called after a new
        # apc arrives. MPay24 will verify that all the information we received are correct and will return a
        # ok or a fail.
        #
        # Example:
        #
        #   def ipn
        #     notify = MPay24Notification.new(request.raw_post)
        #
        #     if notify.acknowledge
        #       ... process order ... if notify.complete?
        #     else
        #       ... log possible hacking attempt ...
        #     end
        def acknowledge(authcode = nil)
          payload = raw

          uri = URI.parse(MPay24.notification_confirmation_url)

          request = Net::HTTP::Post.new(uri.path)

          request['Content-Length'] = "#{payload.size}"
          request['User-Agent'] = "Active Merchant -- http://activemerchant.org/"
          request['Content-Type'] = "application/x-www-form-urlencoded"

          http = Net::HTTP.new(uri.host, uri.port)
          http.verify_mode    = OpenSSL::SSL::VERIFY_NONE unless @ssl_strict
          http.use_ssl        = true

          response = http.request(request, payload)

          # Replace with the appropriate codes
          raise StandardError.new("Faulty MPay24 result: #{response.body}") unless ["AUTHORISED", "DECLINED"].include?(response.body)
          response.body == "AUTHORISED"
        end

        private

        # Take the posted data and move the relevant data into a hash
        def parse(post)
          @raw = post.to_s
          for line in @raw.split('&')
            key, value = *line.scan( %r{^([A-Za-z0-9_.-]+)\=(.*)$} ).flatten
            params[key] = CGI.unescape(value.to_s) if key.present?
          end
        end
      end
    end
  end
end
