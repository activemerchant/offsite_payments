# Offsite Payments
[![Build Status](https://travis-ci.org/Shopify/offsite_payments.png?branch=master)](https://travis-ci.org/Shopify/offsite_payments)
[![Code Climate](https://codeclimate.com/github/Shopify/offsite_payments.png)](https://codeclimate.com/github/Shopify/offsite_payments)

Offsite Payments is an extraction from the ecommerce system [Shopify](http://www.shopify.com). Shopify's requirements for a simple and unified API to handle dozens of different offsite payment pages (often called hosted payment pages) with very different exposed APIs was the chief principle in designing the library.

It was developed for usage in Ruby on Rails web applications and integrates seamlessly
as a Rails plugin. It should also work as a stand alone Ruby library, but much of the benefit is in the ActionView helpers which are Rails-specific.

Offsite Payments has been in production use (originally as part of the [ActiveMerchant](https://github.com/Shopify/active_merchant) project) since June 2006. It is maintained by the [Shopify](http://www.shopify.com) team, with much help from an ever-growing set of contributors.

## Installation

### From Git

You can check out the latest source from git:

    git clone https://github.com/Shopify/offsite_payments.git

### From RubyGems

Installation from RubyGems:

    gem install offsite_payments

Or, if you're using Bundler, just add the following to your Gemfile:

    gem 'offsite_payments'

[API documentation](http://rubydoc.info/github/Shopify/offsite_payments/master/file/README.md).

## Supported Integrations

* [2 Checkout](http://www.2checkout.com)
* [A1Agregator](http://a1agregator.ru/) - RU
* [Authorize.Net SIM](http://developer.authorize.net/api/sim/) - US
* [Banca Sella GestPay](https://www.gestpay.it/)
* [Chronopay](http://www.chronopay.com)
* [DirecPay](http://www.timesofmoney.com/direcpay/jsp/home.jsp)
* [Direct-eBanking / sofortueberweisung.de by Payment-Networks AG](https://www.payment-network.com/deb_com_en/merchantarea/home) - DE, AT, CH, BE, UK, NL
* [Dotpay](http://dotpay.pl)
* [Doku](http://doku.com)
* [Dwolla](https://www.dwolla.com/default.aspx)
* [ePay](http://www.epay.dk/epay-payment-solutions/)
* [First Data](https://firstdata.zendesk.com/entries/407522-first-data-global-gateway-e4sm-payment-pages-integration-manual)
* [HiTRUST](http://www.hitrust.com.hk/)
* [Moneybookers](http://www.moneybookers.com)
* [Nochex](http://www.nochex.com)
* [PagSeguro](http://www.pagseguro.com.br/) - BR
* [Paxum](https://www.paxum.com/)
* [PayPal Website Payments Standard](https://www.paypal.com/cgi-bin/webscr?cmd#_wp-standard-overview-outside)
* [Paysbuy](https://www.paysbuy.com/) - TH
* [Platron](https://www.platron.ru/) - RU
* [RBK Money](https://rbkmoney.ru/) - RU
* [Robokassa](http://robokassa.ru/) - RU
* [SagePay Form](http://www.sagepay.com/products_services/sage_pay_go/integration/form)
* [Suomen Maksuturva](https://www.maksuturva.fi/services/vendor_services/integration_guidelines.html)
* [Valitor](http://www.valitor.is/) - IS
* [Verkkomaksut](http://www.verkkomaksut.fi) - FI
* [WebMoney](http://www.webmoney.ru) - RU
* [WebPay](http://webpay.by/)
* [WorldPay](http://www.worldpay.com)

## Contributing

The source code is hosted at [GitHub](http://github.com/Shopify/offsite_payments), and can be fetched using:

    git clone https://github.com/Shopify/offsite_payments.git

Please don't touch the CHANGELOG in your pull requests, we'll add the appropriate CHANGELOG entries at release time.
