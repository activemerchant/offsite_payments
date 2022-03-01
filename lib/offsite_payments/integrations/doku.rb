# frozen_string_literal: true

module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module Doku
      def self.service_url
        'https://apps.myshortcart.com/payment/request-payment/'
      end

      def self.notification(post, options = {})
        Notification.new(post, options)
      end

      def self.return(post, options = {})
        Return.new(post, options)
      end

      # # Example.
      #
      #  payment_service_for('ORDER_ID', 'DOKU_STORE_ID', :service => :doku,  :amount => 155_000, :shared_key => 'DOKU_SHARED_KEY') do |service|
      #
      #    service.customer :name              => 'Ismail Danuarta',
      #                     :email             => 'ismail.danuarta@gmail.com',
      #                     :mobile_phone      => '085779280093',
      #                     :working_phone     => '0215150555',
      #                     :home_phone        => '0215150555',
      #                     :birth_date        => '1991-09-11'
      #
      #    service.billing_address :city     => 'Jakarta Selatan',
      #                            :address  => 'Jl. Jendral Sudirman kav 59, Plaza Asia Office Park Unit 3',
      #                            :state    => 'DKI Jakarta',
      #                            :zip      => '12190',
      #                            :country  => 'ID'

      #    service.shipping_address :city     => 'Jakarta',
      #                             :address  => 'Jl. Jendral Sudirman kav 59, Plaza Asia Office Park Unit 3',
      #                             :state    => 'DKI Jakarta',
      #                             :zip      => '12190',
      #                             :country  => 'ID'
      #
      #    service.url 'http://yourstore.com'
      #
      # end
      #
      class Helper < OffsitePayments::Helper
        def initialize(order, account, options = {})
          @shared_key      = options.delete(:credential2)
          @transidmerchant = order
          super
        end

        def form_fields
          add_field 'WORDS', words
          add_field 'BASKET', basket
          add_field 'TRANSIDMERCHANT', @transidmerchant
          @fields
        end

        def customer(params = {})
          add_field mappings[:customer][:name], "#{params[:first_name]} #{params[:last_name]}"
          add_field mappings[:customer][:email], params[:email]
          add_field mappings[:customer][:phone], params[:phone]
          add_field mappings[:customer][:mobile_phone], params[:mobile_phone]
          add_field mappings[:customer][:working_phone], params[:working_phone]
          add_field mappings[:customer][:birth_date], params[:birth_date]
        end

        mapping :account,           'STOREID'
        mapping :amount,            'AMOUNT'
        mapping :cancel_return_url, 'URL'


        mapping :customer, :name          => 'CNAME',
                           :email         => 'CEMAIL',
                           :phone         => 'CHPHONE',
                           :mobile_phone  => 'CMPHONE',
                           :working_phone => 'CWPHONE',
                           :birth_date    => 'BIRTHDATE'

        mapping :billing_address, :city     => 'CCITY',
                                  :address1 => 'CADDRESS',
                                  :state    => 'CSTATE',
                                  :zip      => 'CZIPCODE',
                                  :country  => 'CCOUNTRY'

        mapping :shipping_address,  :city     => 'SCITY',
                                    :address1 => 'SADDRESS',
                                    :state    => 'SSTATE',
                                    :zip      => 'SZIPCODE',
                                    :country  => 'SCOUNTRY'

        private

        def basket
          "Checkout #{@transidmerchant},#{@fields['AMOUNT']},1,#{@fields['AMOUNT']}"
        end

        def words
          @words ||= Digest::SHA1.hexdigest("#{ @fields['AMOUNT'] }#{ @shared_key }#{ @transidmerchant }")
        end

        def add_address(key, params)
          return if mappings[key].nil?

          code = lookup_country_code(params.delete(:country), :numeric)
          add_field(mappings[key][:country], code)
          add_fields(key, params)
        end
      end

      class Notification < OffsitePayments::Notification
        self.production_ips = ['103.10.128.11', '103.10.128.14']

        def complete?
          status.present?
        end

        def item_id
          params['TRANSIDMERCHANT']
        end

        def gross
          params['AMOUNT']
        end

        def status
          case params['RESULT']
          when 'Success'
            'Completed'
          when 'Fail'
            'Failed'
          end
        end

        def currency
          'IDR'
        end

        def words
          params['WORDS']
        end

        def type
          if words && params['STOREID']
            'verify'
          elsif status
            'notify'
          end
        end

        # no unique ID is generated by Doku at any point in the process,
        # so use the same as the original order number.
        def transaction_id
          params['TRANSIDMERCHANT']
        end

        def acknowledge(authcode = nil)
          case type
          when 'verify'
            words == Digest::SHA1.hexdigest("#{gross}#{@options[:credential2]}#{item_id}")
          when 'notify'
            true
          else
            false
          end
        end
      end

      class Return < OffsitePayments::Return
      end
    end
  end
end
