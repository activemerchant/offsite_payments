module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    # Documentation:
    # https://www.paxum.com/payment_docs/page.php?name=apiIntroduction
    module Paxum
      mattr_accessor :test_url
      self.test_url = 'https://paxum.com/payment/phrame.php?action=displayProcessPaymentLogin'

      mattr_accessor :production_url
      self.production_url = 'https://paxum.com/payment/phrame.php?action=displayProcessPaymentLogin'

      mattr_accessor :signature_parameter_name
      self.signature_parameter_name = 'key'

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

      def self.helper(order, account, options = {})
        Helper.new(order, account, options)
      end

      def self.notification(query_string, options = {})
        Notification.new(query_string, options)
      end

      module Common
        def generate_signature_string
          @raw_post.slice!(0) if @raw_post.starts_with?("&")
          @raw_post = CGI.unescape(@raw_post)
          @raw_post = "&#{@raw_post}" unless @raw_post.starts_with?("&")
          arr = @raw_post.split('&')
          arr.delete(arr.last)
          data = arr.join('&')

          (data + secret)
        end

        def generate_signature
          Digest::MD5.hexdigest(generate_signature_string)
        end
      end

      class Helper < OffsitePayments::Helper
        include Common

        def initialize(order, account, options = {})
          @paxum_options = options.dup
          options.delete(:description)
          options.delete(:fail_url)
          options.delete(:success_url)
          options.delete(:result_url)
          super
          add_field "button_type_id", "1"
          add_field "variables", "notify_url=#{@paxum_options[:result_url]}"
          @paxum_options.each do |key, value|
            add_field mappings[key], value
          end
        end

        def form_fields
          @fields
        end

        def params
          @fields
        end

        mapping :account, 'business_email'
        mapping :amount, 'amount'
        mapping :currency, 'currency'
        mapping :order, 'item_id'
        mapping :description, 'item_name'
        mapping :fail_url, 'cancel_url'
        mapping :success_url, 'finish_url'
        mapping :result_url, 'notify_url'
      end

      class Notification < OffsitePayments::Notification
        include Common

        def initialize(post, options = {})
          @raw_post = post.dup
          post.slice!(0)
          super
        end

        def self.recognizes?(params)
          (params.has_key?('transaction_item_id') && params.has_key?('transaction_amount'))
        end

        def security_key
          params["key"]
        end

        def secret
          @options[:secret]
        end

        def acknowledge(authcode = nil)
          (security_key == generate_signature)
        end
      end
    end
  end
end
