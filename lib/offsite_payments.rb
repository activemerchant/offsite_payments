fail %q{
  Money is required for offsite_payments to work, please refer to https://github.com/activemerchant/offsite_payments#money-gem-dependency
} unless defined?(Money)
require 'securerandom'
require 'cgi'
require "timeout"
require "socket"
require 'bigdecimal'
require 'bigdecimal/util'

require 'active_utils'

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
