module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module Razorpay

      mattr_accessor :service_url
      self.service_url = 'https://checkout.razorpay.com/'

      # options should be { credential1: "your key-id", credential2: "your key-secret" }
      def self.notification(post, options = {})
        Notification.new(post, options = {})
      end

      def self.sign(fields, key_secret)
        fields.slice!(*['razorpay_payment_id', 'amount', 'currency', 'merchant_order_id'])
        OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA1.new, key_secret, Hash[fields.sort].values.join('|'))
      end

      class Helper < OffsitePayments::Helper

        mapping :account,          'key'
        mapping :currency,         'currency'
        mapping :order,            'merchant_order_id'
        mapping :amount,           'amount'
        mapping :country,          'notes[shop_country]'
        mapping :account_name,     'name'
        mapping :description,      'description'
        mapping :invoice,          'notes[invoice]'

        mapping :customer, :name       => 'prefill[name]',
                           :email      => 'prefill[email]',
                           :phone      => 'prefill[contact]'

        mapping :shipping_address, :first_name => 'notes[shipping_first_name]',
                                   :last_name =>  'notes[shipping_last_name]',
                                   :city =>       'notes[shipping_city]',
                                   :company =>    'notes[shipping_company]',
                                   :address1 =>   'notes[shipping_address1]',
                                   :address2 =>   'notes[shipping_address2]',
                                   :state =>      'notes[shipping_state]',
                                   :zip =>        'notes[shipping_zip]',
                                   :country =>    'notes[shipping_country]',
                                   :phone =>      'notes[shipping_phone]'

        mapping        :return_url, 'url[callback]'
        mapping :cancel_return_url, 'url[cancel]'

        def initialize(order, account, options = {})
          @key_secret = options[:credential2]
          super
        end

        def amount=(amount)
          # razorpay accepts amounts in paisa (ruppes*100)
          add_field(mappings[:amount], (amount*100).round)
        end

        def form_fields
          sign_fields
        end

        def customer(params = {})
          add_field(mappings[:customer][:name], full_name(params))
          add_field(mappings[:customer][:email], params[:email])
          add_field(mappings[:customer][:phone], params[:phone])
        end

        def full_name(params)
          return if params[:name].blank? && params[:first_name].blank? && params[:last_name].blank?

          params[:name] || "#{params[:first_name]} #{params[:last_name]}"
        end

        def sign_fields
          signature = Razorpay.sign(@fields, @key_secret)
          @fields.merge!('signature' => signature)
        end
      end

      class Notification < OffsitePayments::Notification

        def initialize(post, options = {})
          super
          @key_secret = options[:credential2]
        end

        def item_id
          params['merchant_order_id']
        end

        # Internal razorpay payment id
        def transaction_id
          params['razorpay_payment_id']
        end

        def currency
          params['currency']
        end

        # the money amount we received in X.2 decimal.
        # amount is in paise, so we divide it by 100
        def gross
          (params['amount'].to_i/100).to_f
        end

        def status
          'Completed'
        end

        # Acknowledge the transaction to Razorpay. This method has to be called after a new
        # apc arrives. Razorpay will verify that all the information we received are correct and will return a
        # ok or a fail.
        #
        def acknowledge(authcode = nil)
          parse(raw)
          params['signature'] == generate_signature
        end

        def generate_signature
          Razorpay.sign(params, @key_secret)
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

      class Return < OffsitePayments::Return
      end
    end
  end
end
