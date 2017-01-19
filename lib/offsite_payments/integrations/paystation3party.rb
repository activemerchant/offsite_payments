module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module Paystation3party
      mattr_accessor :service_url

      def self.notification(post, options = {})
        Notification.new(post)
      end

      def self.return(post, options = {})
        Return.new(post, options)
      end

      class InvalidPaystationNotification < StandardError         
      end
      class PaystationIdRequired < StandardError         
      end
      class NoAmountSpecifiedError <StandardError
      end
      class NoGatewaySpecifiedError <StandardError
      end        
      
      class Helper < OffsitePayments::Helper
        def money_format 
          :cents
        end
        def initialize(order, paystation_id,  options = {})
          if !options.has_key?(:amount)
            raise NoAmountSpecifiedError
          end
          if !options.has_key?(:gateway_id)
            raise NoGatewaySpecifiedError
          end            
          @parameters = {:order => order,
            :paystation_id => paystation_id,
            :amount=>options[:amount],
            :gateway_id=> options[:gateway_id],
            :test_mode=>options[:test_mode],
            :order=>order              
          }            
          options.delete(:gateway_id)
          options.delete(:test_mode)
          super
        end
          
        def credential_based_url

          uri = URI.parse ("https://www.paystation.co.nz/direct/paystation.dll")
          
          https = Net::HTTP.new(uri.host, uri.port)
          https.use_ssl = true # if uri.scheme == 'https'
          https.verify_mode = OpenSSL::SSL::VERIFY_NONE
          request = Net::HTTP::Post.new(uri.request_uri)

          post = {}
          if @parameters[:tm]
            post['tm'] = "T" # test mode
          end
          post['pstn_nr'] = "t"
          time = Time.now.to_i.to_s
          post['pstn_ms'] = (0...20).map { (65 + rand(26)).chr }.join	
          post['pstn_ms'] += time+@parameters[:order].to_s
          post['pstn_pi'] = @parameters[:paystation_id].to_s
            
          post['pstn_mr'] = @parameters[:order].to_s
          post['pstn_am'] = (@parameters[:amount]*100).to_s
          post['pstn_gi'] = @parameters[:gateway_id].to_s
          post['paystation'] = "_empty"
            
            
            
          request.set_form_data(post);
          response = https.request(request)
            
          case response
          when Net::HTTPSuccess then
            data =response.body
          when Net::HTTPRedirection then
            location = response['location']
            return location
          else 
            return nil         
          end

          response = {}
          xml = REXML::Document.new(data)        
          xml.elements.each("#{xml.root.name}/*") do |element|
            response[element.name.underscore.to_sym] = element.text
          end
            
          if (response[:ec]==nil) 
            return response[:digital_order]
          else 
            return {:ec=>response[:ec], :em=>response[:em]}
          end
        end
      end
      class Return < OffsitePayments::Return  

        def money_format
          :cents
        end
        def initialize(query, options)
          if (options.key?(:quickLookUp) && options[:quickLookUp] && !options.key?(:pi))
            raise PaystationIdRequired
          end
          #requires!(options, :paystation_id)
          if query.class == String
            begin
              notification = Notification.new(query, options)
              @params = notification.params
            rescue
              raise InvalidPaystationNotification 
            end
          elsif query.class == Hash  
            @params = query
          elsif query.class == HashWithIndifferentAccess 
            @params = query.to_hash
          else
              
            raise InvalidPaystationNotification
          end
            
          if @params.empty?              
            raise InvalidPaystationNotification
          end
          #if @params.length!=5
          #  raise xInvalidPaystationNotification
          #end 

          @params = @params.merge(options)
          success?
        end

        def success?
            
          ec = @params["ec"].to_i
          if (ec!=0)
            return false
          elsif ((!@params.key?(:quickLookUp) || @params[:quickLookUp]==false) && ec==0)
            return true
          else
            @params["am"] = 0
            if (@params["ec"]==nil || @params["ti"]==nil || @params[:pi]==nil)
              return false
            end 
              
            # return @params              
            uri = URI "https://www.paystation.co.nz/lookup/quick/?pi="+@params[:pi]+"&ti="+@params["ti"];
             
            https = Net::HTTP.new(uri.host, uri.port)
              
            https.use_ssl = true # if uri.scheme == 'https'
            https.verify_mode = OpenSSL::SSL::VERIFY_NONE
            data = https.request(Net::HTTP::Get.new(uri.request_uri)) 
            data=data.body
            doc = Nokogiri::XML(data)

            lookupCode = doc.xpath("//PaystationQuickLookup//LookupStatus//LookupCode").first().text().to_i

            if(lookupCode>0)
              @params["ec"]=-1
              @params["em"] = doc.xpath("//PaystationQuickLookup//LookupStatus//LookupMessage").first().text()
              return false
            end
              
            @params["ec"]= doc.xpath("//PaystationQuickLookup//LookupResponse//PaystationErrorCode").first().text().to_i
              
            if (@params["ec"] > 0)
              @params["em"] = doc.xpath("//PaystationQuickLookup//LookupResponse//PaystationErrorMessageExtended").first().text()
              return false
            end

            ql_ms = doc.xpath("//PaystationQuickLookup//LookupResponse//MerchantSession").first().text()
              
            if !ql_ms.eql?(@params["ms"])
              @params["em"] =""
              @params["ec"] =-1
              return false
            end
              
            @params["am"] = doc.xpath("//PaystationQuickLookup//LookupResponse//PurchaseAmount").first().text().to_i
              
            return true
              
          end
        end

          
        def cancelled?
          self.success?
        end

        def message
          return @params["em"]
        end

      end
        
      class Notification < OffsitePayments::Notification
        @money_format = :cents
        @result = nil
        def initialize (post, options={})
          super
          @data = post          
          @result = process_xml
        end
          
        def empty!
          super
          @data = nil
          @result = nil
        end
          
        def gross_cents
          if @result[:ec] == 0 
            @result[:am]
          end
        end          

        def valid_sender
          raise NotImplementedError
        end
          
        def complete?
          @result[:ec] == 0
        end 

        def order_id
          @result[:mr]
        end

        def transaction_id
          @result[:ti]
        end

        # Time this payment was received by the client in UTC time.
        def transaction_time
          @result[:time]
        end

        # the money amount we received in X.2 decimal.
        def gross
          if @result[:ec] == 0 
            @result[:am] /100.0
          end
        end

        # Was this a test transaction?
        def test?
          @result[:tm]=='T' || @result[:tm]=='t'
        end

        def status
          if @result[:ec]==0
            return 'Completed'
          else
            return 'Failed'
          end
        end

        def card_type
          @result[:ct]
        end

        def acknowledge(authcode = nil)com
          return true
        end
          
        private

        def process_xml
          {
            :ct => @data["PaystationPaymentVerification"]["ct"],
            :ec => @data["PaystationPaymentVerification"]["ec"].to_i,
            :em => @data["PaystationPaymentVerification"]["em"],
            :ti => @data["PaystationPaymentVerification"]["ti"],
            :tm => @data["PaystationPaymentVerification"]["tm"],
            :am => @data["PaystationPaymentVerification"]["am"].to_i,
            :pi => @data["PaystationPaymentVerification"]["Username"],
            :time => @data["PaystationPaymentVerification"]["TransactionTime"],
            :mr => @data["PaystationPaymentVerification"]["merchant_ref"]           
          }
        end
      end
    end
  end
end
