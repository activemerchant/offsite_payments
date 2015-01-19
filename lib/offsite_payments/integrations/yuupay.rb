module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module Yuupay 
      include Universal
      class Helper < Universal::Helper
        def forward_url 
          'https://checkout.yuupay.net/payment/index.php'
        end
      end
    end
  end
end
