require 'securerandom'
require 'builder'
require 'cgi'
require 'rexml/document'

require 'active_support'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/hash/conversions'
require 'active_support/core_ext/object/conversions'
require 'active_support/core_ext/class/attribute'
require 'active_support/core_ext/enumerable.rb'

if(!defined?(ActiveSupport::VERSION) || (ActiveSupport::VERSION::STRING < "4.1"))
  require 'active_support/core_ext/class/attribute_accessors'
end

require 'active_support/core_ext/class/delegating_attributes'
require 'active_support/core_ext/module/attribute_accessors'

begin
  require 'active_support/base64'

  unless defined?(Base64)
    Base64 = ActiveSupport::Base64
  end

  unless Base64.respond_to?(:strict_encode64)
    def Base64.strict_encode64(v)
      ActiveSupport::Base64.encode64s(v)
    end
  end
rescue LoadError
  require 'base64'
end

require 'active_utils/common/network_connection_retries'
require 'active_utils/common/connection'
require 'active_utils/common/requires_parameters'
require 'active_utils/common/country'
require 'active_utils/common/error'
require 'active_utils/common/post_data'
require 'active_utils/common/posts_data'
require 'active_utils/common/currency_code'

require "offsite_payments/helper"
require "offsite_payments/notification"
require "offsite_payments/return"
require "offsite_payments/integrations"

module OffsitePayments
  # Return the matching integration module
  # You can then get the notification from the module
  # * <tt>bogus</tt>: Bogus - Does nothing (for testing)
  # * <tt>chronopay</tt>: Chronopay
  # * <tt>paypal</tt>: Paypal
  #
  #   chronopay = OffsitePayments.integration('chronopay')
  #   notification = chronopay.notification(raw_post)
  #
  def self.integration(name)
    Integrations.const_get("#{name.to_s.downcase}".camelize)
  end

  mattr_accessor :mode
  self.mode = :production

  # A check to see if we're in test mode
  def self.test?
    self.mode == :test
  end

  CURRENCIES_WITHOUT_FRACTIONS = [ 'BIF', 'BYR', 'CLP', 'CVE', 'DJF', 'GNF', 'HUF', 'ISK', 'JPY', 'KMF', 'KRW', 'PYG', 'RWF', 'TWD', 'UGX', 'VND', 'VUV', 'XAF', 'XOF', 'XPF' ]
end
