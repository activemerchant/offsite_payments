require 'securerandom'
require 'cgi'
require "timeout"
require "socket"

require 'active_support/core_ext/class/delegating_attributes'

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
require "offsite_payments/action_view_helper"

I18n.enforce_available_locales = false

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
