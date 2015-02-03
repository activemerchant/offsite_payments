module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module MollieMistercash
      include Mollie

        RedirectError = Class.new(ActiveUtils::ActiveUtilsError)

        def self.notification(post, options = {})
          Notification.new(post, options)
        end

        def self.return(post, options = {})
          Return.new(post, options)
        end

        def self.live?
          OffsitePayments.mode == :production
        end

        def self.create_payment(token, params)
          API.new(token).post_request('payments', params)
        end

        def self.check_payment_status(token, payment_id)
          API.new(token).get_request("payments/#{payment_id}")
        end

        def self.requires_redirect_param?
          false
        end

        class Helper < OffsitePayments::Helper
          attr_reader :transaction_id, :redirect_parameters, :token

            def initialize(order, account, options = {})
              @token = account
              @redirect_parameters = {
                :amount => options[:amount],
                :description => options[:description],
                :redirectUrl => options[:return_url],
                :method => 'mistercash',
                :metadata => { :order => order }
              }

              @redirect_parameters[:webhookUrl] = options[:notify_url] if options[:notify_url]

              super

              raise ArgumentError, "The return_url option needs to be set." if options[:return_url].blank?
              raise ArgumentError, "The description option needs to be set." if options[:description].blank?
            end

            def credential_based_url
              response = request_redirect
              uri = URI.parse(response['links']['paymentUrl'])
              uri.to_s
            end

            def form_method
              "GET"
            end

            def request_redirect
              MollieMistercash.create_payment(token, redirect_parameters)
            rescue ActiveUtils::ResponseError => e
              case e.response.code
              when '401', '403', '422'
                error = JSON.parse(e.response.body)['error']['message']
                raise ActionViewHelperError, error
              when '503'
                raise ActionViewHelperError, 'Service temporarily unavailable. Please try again.'
              else
                raise
              end
            end

        end

        class Notification < OffsitePayments::Notification
          def initialize(post_arguments, options = {})
            super

            raise ArgumentError, "The transaction_id needs to be included in the query string." if transaction_id.nil?
            raise ArgumentError, "The credential1 option needs to be set to the Mollie API key." if api_key.blank?
          end

          def complete?
            true
          end

          def item_id
            params['metadata']['order']
          end

          def transaction_id
            params['id']
          end

          def api_key
            @options[:credential1]
          end

          def currency
            "EUR"
          end

          # the money amount we received in X.2 decimal.
          def gross
            @params['amount']
          end

          def gross_cents
            (BigDecimal.new(@params['amount'], 2) * 100).to_i
          end

          def status
            case @params['status']
              when 'open';                 'Pending'
              when 'paidout', 'paid';      'Completed'
              else                         'Failed'
            end
          end

          def test?
            @params['mode'] == 'test'
          end

          def acknowledge(authcode = nil)
            @params = check_payment_status(transaction_id)
            true
          end

          def check_payment_status(transaction_id)
            MollieMistercash.check_payment_status(@options[:credential1], transaction_id)
          end
        end

        class Return < OffsitePayments::Return
        end

    end
  end
end
