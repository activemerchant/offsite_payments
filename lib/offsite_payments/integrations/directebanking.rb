module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module Directebanking
      # Supported countries:
      # Germany - DE
      # Austria - AT
      # Belgium - BE
      # Netherlands - NL
      # Switzerland - CH
      # Great Britain - GB

      # Overwrite this if you want to change the directebanking test url
      mattr_accessor :test_url
      self.test_url = 'https://www.directebanking.com/payment/start'

      # Overwrite this if you want to change the directebanking production url
      mattr_accessor :production_url
      self.production_url = 'https://www.directebanking.com/payment/start'

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

      def self.notification(post, options = {})
        Notification.new(post, options)
      end

      def self.return(post, options = {})
        Return.new(post, options)
      end

      class Helper < OffsitePayments::Helper
        # All credentials are mandatory and need to be set
        #
        # credential1: User ID
        # credential2: Project ID
        # credential3: Project Password (Algorithm: SH1)
        # credential4: Notification Password (Algorithm: SH1)
        def initialize(order, account, options = {})
          super
          add_field('user_variable_0', order)
          add_field('project_id', options[:credential2])
          @project_password = options[:credential3]
        end

        SIGNATURE_FIELDS = [
          :user_id,
          :project_id,
          :sender_holder,
          :sender_account_number,
          :sender_bank_code,
          :sender_country_id,
          :amount,
          :currency_id,
          :reason_1,
          :reason_2,
          :user_variable_0,
          :user_variable_1,
          :user_variable_2,
          :user_variable_3,
          :user_variable_4,
          :user_variable_5
        ]

        SIGNATURE_IGNORE_AT_METHOD_CREATION_FIELDS = [
          :user_id,
          :amount,
          :project_id,
          :currency_id,
          :user_variable_0,
          :user_variable_1,
          :user_variable_2,
          :user_variable_3
        ]

        SIGNATURE_FIELDS.each do |key|
          if !SIGNATURE_IGNORE_AT_METHOD_CREATION_FIELDS.include?(key)
            mapping "#{key}".to_sym, "#{key.to_s}"
          end
        end

        # Need to format the amount to have 2 decimal places
        def amount=(money)
          cents = money.respond_to?(:cents) ? money.cents : money
          raise ArgumentError, "amount must be a Money object or an integer" if money.is_a?(String)
          raise ActionViewHelperError, "amount must be greater than $0.00" if cents.to_i <= 0

          add_field mappings[:amount], sprintf("%.2f", cents.to_f/100)
        end

        def generate_signature_string
          # format of signature: user_id|project_id|sender_holder|sender_account_number|sender_bank_code| sender_country_id|amount|currency_id|reason_1|reason_2|user_variable_0|user_variable_1|user_variable_2|user_variable_3|user_variable_4|user_variable_5|project_password
          SIGNATURE_FIELDS.map {|key| @fields[key.to_s]} * "|" + "|#{@project_password}"
        end

        def generate_signature
          Digest::SHA1.hexdigest(generate_signature_string)
        end

        def form_fields
          @fields.merge('hash' => generate_signature)
        end

        mapping :account, 'user_id'
        mapping :amount, 'amount'
        mapping :currency, 'currency_id'
        mapping :description, 'reason_1'

        mapping :return_url, 'user_variable_1'
        mapping :cancel_return_url, 'user_variable_2'
        mapping :notify_url, 'user_variable_3'
      end

      class Notification < OffsitePayments::Notification
        def initialize(data, options)
          if options[:credential4].nil?
            raise ArgumentError, "You need to provide the notification password (SH1) as the option :credential4 to verify that the notification originated from Directebanking (Payment Networks AG)"
          end
          super
        end

        def complete?
          status == 'Completed'
        end

        def item_id
          params['user_variable_0']
        end

        def transaction_id
          params['transaction']
        end

        # When was this payment received by the client.
        def received_at
          Time.parse(params['created']) if params['created']
        end

        # the money amount we received in X.2 decimal.
        def gross
          "%.2f" % params['amount'].to_f
        end

        def status
          'Completed'
        end

        def currency
          params['currency_id']
        end

        def test?
          params['sender_bank_name'] == 'Testbank'
        end

        # for verifying the signature of the URL parameters
        PAYMENT_HOOK_SIGNATURE_FIELDS = [
          :transaction,
          :user_id,
          :project_id,
          :sender_holder,
          :sender_account_number,
          :sender_bank_code,
          :sender_bank_name,
          :sender_bank_bic,
          :sender_iban,
          :sender_country_id,
          :recipient_holder,
          :recipient_account_number,
          :recipient_bank_code,
          :recipient_bank_name,
          :recipient_bank_bic,
          :recipient_iban,
          :recipient_country_id,
          :international_transaction,
          :amount,
          :currency_id,
          :reason_1,
          :reason_2,
          :security_criteria,
          :user_variable_0,
          :user_variable_1,
          :user_variable_2,
          :user_variable_3,
          :user_variable_4,
          :user_variable_5,
          :created
        ]

        PAYMENT_HOOK_IGNORE_AT_METHOD_CREATION_FIELDS = [
          :transaction,
          :amount,
          :currency_id,
          :user_variable_0,
          :user_variable_1,
          :user_variable_2,
          :user_variable_3,
          :created
        ]

        # Provide access to raw fields
        PAYMENT_HOOK_SIGNATURE_FIELDS.each do |key|
          if !PAYMENT_HOOK_IGNORE_AT_METHOD_CREATION_FIELDS.include?(key)
            define_method(key.to_s) do
               params[key.to_s]
            end
          end
        end

        def generate_signature_string
          #format is: transaction|user_id|project_id|sender_holder|sender_account_number|sender_bank_code|sender_bank_name|sender_bank_bic|sender_iban|sender_country_id|recipient_holder|recipient_account_number|recipient_bank_code|recipient_bank_name|recipient_bank_bic|recipient_iban|recipient_country_id|international_transaction|amount|currency_id|reason_1|reason_2|security_criteria|user_variable_0|user_variable_1|user_variable_2|user_variable_3|user_variable_4|user_variable_5|created|notification_password
          PAYMENT_HOOK_SIGNATURE_FIELDS.map {|key| params[key.to_s]} * "|" + "|#{@options[:credential4]}"
        end

        def generate_signature
          Digest::SHA1.hexdigest(generate_signature_string)
        end

        def acknowledge(authcode = nil)
          # signature_is_valid?
          generate_signature.to_s == params['hash'].to_s
        end
      end

      class Return < OffsitePayments::Return
      end
    end
  end
end
