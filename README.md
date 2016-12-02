# Offsite Payments
[![Build Status](https://travis-ci.org/activemerchant/offsite_payments.svg?branch=master)](https://travis-ci.org/activemerchant/offsite_payments)
[![Code Climate](https://codeclimate.com/github/activemerchant/offsite_payments/badges/gpa.svg)](https://codeclimate.com/github/activemerchant/offsite_payments)

Offsite Payments is an extraction from the ecommerce system [Shopify](http://www.shopify.com). Shopify's requirements for a simple and unified API to handle dozens of different offsite payment pages (often called hosted payment pages) with very different exposed APIs was the chief principle in designing the library.

It was developed for usage in Ruby on Rails web applications and integrates seamlessly
as a Rails plugin. It should also work as a stand alone Ruby library, but much of the benefit is in the ActionView helpers which are Rails-specific.

Offsite Payments has been in production use (originally as part of the [ActiveMerchant](https://github.com/activemerchant/active_merchant) project) since June 2006. It is maintained by the [Shopify](http://www.shopify.com) team, with much help from an ever-growing set of contributors.

The addition of your gateway to offsite_payments does not guarantee placement within Shopify. In order to have your gateway considered, please send an email to payment-integrations@shopify.com with **Offsite Payments Integration** in the subject. Be sure to include:

1. Name, URL & description of the payment provider you wish to integrate
2. Markets served by this integration
3. List of major supported payment methods
4. Your most recent Certificate of PCI Compliance
5. Reason that the [Universal API](https://github.com/activemerchant/offsite_payments/blob/master/lib/offsite_payments/integrations/universal.rb)* cannot be used for your integration.

*The Universal API defines a standard set of requests and callbacks that can be used to integrate with Shopify. A sample app and documentation are hosted [here](https://github.com/Shopify/offsite-gateway-sim). The Universal API should be used for all integrations in which placement within Shopify is the desired outcome. 

## Installation

### From Git

You can check out the latest source from git:

    git clone https://github.com/activemerchant/offsite_payments.git

### From RubyGems

Installation from RubyGems:

    gem install offsite_payments

Or, if you're using Bundler, just add the following to your Gemfile:

    gem 'offsite_payments'

[API documentation](http://www.rubydoc.info/github/activemerchant/offsite_payments/master).

## Supported Integrations

* [2 Checkout](http://www.2checkout.com)
* [A1Agregator](http://a1agregator.ru/) - RU
* [Authorize.Net SIM](http://developer.authorize.net/api/sim/) - US
* [Banca Sella GestPay](https://www.gestpay.it/)
* [BitPay](https://bitpay.com/)
* [Chronopay](http://www.chronopay.com)
* [DirecPay](http://www.timesofmoney.com/direcpay/jsp/home.jsp)
* [Direct-eBanking / sofortueberweisung.de by Payment-Networks AG](https://www.payment-network.com/deb_com_en/merchantarea/home) - DE, AT, CH, BE, UK, NL
* [Dotpay](http://dotpay.pl)
* [Doku](http://doku.com)
* [Dwolla](https://www.dwolla.com/default.aspx)
* [ePay](http://www.epay.dk/epay-payment-solutions/)
* [First Data](https://firstdata.zendesk.com/entries/407522-first-data-global-gateway-e4sm-payment-pages-integration-manual)
* [HiTRUST](http://www.hitrust.com.hk/)
* [MOLPay](http://www.molpay.com/v2/) - MY, SG, ID, TH, VN, PH, CN, AU
* [Moneybookers](http://www.moneybookers.com)
* [Nochex](http://www.nochex.com)
* [PagSeguro](http://www.pagseguro.com.br/) - BR
* [Paxum](https://www.paxum.com/)
* [PayPal Website Payments Standard](https://www.paypal.com/cgi-bin/webscr?cmd#_wp-standard-overview-outside)
* [PayDollar](http://www.paydollar.com)
* [Paysbuy](https://www.paysbuy.com/) - TH
* [Platron](https://www.platron.ru/) - RU
* [Realex](http://www.realexpayments.com)
* [RBK Money](https://rbkmoney.ru/) - RU
* [Robokassa](http://robokassa.ru/) - RU
* [SagePay Form](http://www.sagepay.com/products_services/sage_pay_go/integration/form)
* [Suomen Maksuturva](https://www.maksuturva.fi/services/vendor_services/integration_guidelines.html)
* [Valitor](http://www.valitor.is/) - IS
* [Verkkomaksut](http://www.verkkomaksut.fi) - FI
* [WebMoney](http://www.webmoney.ru) - RU
* [WebPay](http://webpay.by/)
* [WorldPay](http://www.worldpay.com)

## Misc.

- This library is MIT licensed.
- We will gladly accept contributions. See **CONTRIBUTING.md** for more information.
