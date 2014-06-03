module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module Quickpay
      mattr_accessor :service_url
      self.service_url = 'https://secure.quickpay.dk/form/'

      def self.notification(post, options = {})
        Notification.new(post)
      end

      def self.return(post, options = {})
        Return.new(post, options)
      end

      class Helper < OffsitePayments::Helper
        def initialize(order, account, options = {})
          md5secret options.delete(:credential2)
          super
          add_field('protocol', '7')
          add_field('msgtype', 'authorize')
          add_field('language', 'da')
          add_field('autocapture', 0)
          add_field('testmode', test? ? 1 : 0)
          add_field('ordernumber', format_order_number(order))
        end

        def md5secret(value)
          @md5secret = value
        end

        def form_fields
          @fields.merge('md5check' => generate_md5check)
        end

        def generate_md5string
          MD5_CHECK_FIELDS.map {|key| @fields[key.to_s]} * "" + @md5secret
        end

        def generate_md5check
          Digest::MD5.hexdigest(generate_md5string)
        end

        # Limited to 20 digits max
        def format_order_number(number)
          number.to_s.gsub(/[^\w]/, '').rjust(4, "0")[0...20]
        end

        MD5_CHECK_FIELDS = [
          :protocol,
          :msgtype,
          :merchant,
          :language,
          :ordernumber,
          :amount,
          :currency,
          :continueurl,
          :cancelurl,
          :callbackurl,
          :autocapture,
          :autofee,
          :cardtypelock,
          :description,
          :group,
          :testmode,
          :splitpayment,
          :forcemobile,
          :deadline,
          :cardhash
        ]

        mapping :protocol, 'protocol'
        mapping :msgtype, 'msgtype'
        mapping :account, 'merchant'
        mapping :language, 'language'
        mapping :amount, 'amount'
        mapping :currency, 'currency'

        mapping :return_url, 'continueurl'
        mapping :cancel_return_url, 'cancelurl'
        mapping :notify_url, 'callbackurl'

        mapping :autocapture, 'autocapture'
        mapping :autofee, 'autofee'
        mapping :cardtypelock, 'cardtypelock'

        mapping :ipaddress, 'ipaddress'

        mapping :description, 'description'
        mapping :group, 'group'
        mapping :testmode, 'testmode'

        mapping :splitpayment, 'splitpayment'
        mapping :forcemobile, 'forcemobile'
        mapping :deadline, 'deadline'
        mapping :cardhash, 'cardhash'

        mapping :customer, ''
        mapping :billing_address, {}
        mapping :tax, ''
        mapping :shipping, ''
      end

      class Notification < OffsitePayments::Notification
        def complete?
          status == '000'
        end

        def item_id
          params['ordernumber']
        end

        def transaction_id
          params['transaction']
        end

        def received_at
          time = params['time']
          # If time only contains 12 integers then it's pre v5 format
          time = "20#{params['time']}" if /[0-9]{12}/.match(params['time'])
          Time.parse(time)
        end

        def gross
          "%.2f" % (gross_cents / 100.0)
        end

        def gross_cents
          params['amount'].to_i
        end

        def status
          params['qpstat']
        end

        def currency
          params['currency']
        end

        # Provide access to raw fields from quickpay
        %w(
          msgtype
          ordernumber
          state
          chstat
          chstatmsg
          qpstat
          qpstatmsg
          merchant
          merchantemail
          cardtype
          cardnumber
          cardhash
          cardexpire
          splitpayment
          fraudprobability
          fraudremarks
          fraudreport
          fee
        ).each do |attr|
          define_method(attr) do
            params[attr]
          end
        end

        MD5_CHECK_FIELDS = [
          :msgtype,
          :ordernumber,
          :amount,
          :currency,
          :time,
          :state,
          :qpstat,
          :qpstatmsg,
          :chstat,
          :chstatmsg,
          :merchant,
          :merchantemail,
          :transaction,
          :cardtype,
          :cardnumber,
          :cardhash,
          :cardexpire,
          :splitpayment,
          :fraudprobability,
          :fraudremarks,
          :fraudreport,
          :fee
        ]

        def generate_md5string
          MD5_CHECK_FIELDS.map { |key| params[key.to_s] } * "" + @options[:credential2].to_s
        end

        def generate_md5check
          Digest::MD5.hexdigest(generate_md5string)
        end

        # Quickpay doesn't do acknowledgements of callback notifications
        # Instead it uses and MD5 hash of all parameters
        def acknowledge(authcode = nil)
          generate_md5check == params['md5check']
        end

        # Take the posted data and move the relevant data into a hash
        def parse(post)
          # 30 + 12
          #------------------------------8a827a0e6829
          #Content-Disposition: form-data; name="msgtype"
          #
          #subscribe
          #------------------------------8a827a0e6829
          #Content-Disposition: form-data; name="ordernumber"
          #
          #BILP94406

          if post =~ /-{20,40}\w{6,24}/
            @raw = post.to_s
            post.split(/-{20,40}\w{6,24}[\n\r]*/m).each do |part|
              part.scan(/([^\n\r]+)[\n\r]+([^\n\r]*)/m) do |header, value|
                if header.match(/name=["'](.*)["']/)
                  params[$1] = value.strip
                end
              end
            end
          else
            super
          end
        end
      end
    end
  end
end
