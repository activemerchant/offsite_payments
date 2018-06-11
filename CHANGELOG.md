# Offsite Payments CHANGELOG

### Version 2.7.3 (June 11, 2018)
- Update ipay88 urls due to deprecation [pi3r] #298
- Remove test issues from Mollie [elfassy] #297
- Use requested currency instead of authorization currency for WorldPay [joshnuss] #296


### Version 2.7.2 (May 7, 2018)
- Update list of Mollie iDEAL issuers [Smitsel] #292

### Version 2.7.1 (Apr 26, 2018)
- Add application ID tracking to PayuIn [ahamed-wahid] #271

### Version 2.7.0 (Apr 6, 2018)
- Remove Money gem as dependency into gemspec [filipebarcos] #288

### Version 2.6.8 (Mar 22, 2018)
- Ensure values are always sanitized [christianblais] #281
- Updates exception handling for BitPay [joshnuss] #282

### Version 2.6.7 (Mar 7, 2018)
- Add GET retries for Mollie offsites [Girardvjonathan] #279

### Version 2.6.6 (Mar 6, 2018)
- Paytm to accepts phone numbers as customer identifier [christianblais] #275
- Paytm::Notification#checksum_ok? should always return a boolean predicate [pi3r] #273

### Version 2.6.5 (Mar 5, 2018)
- Allow actionpack 5.2 [Edouard-chin] #276

### Version 2.6.4 (Jan 8, 2018)
- Use multiple address fields for WorldPay instead of concatenating them [joshnuss] #270

### Version 2.6.3 (Nov 7, 2017)
- Fix nil coercion to BigDecimal zero in PayuIn [aman-dureja] #265

### Version 2.6.2 (Oct 30, 2017)
- Fix ArgumentError in PayuIn with BigDecimal v1.3.2 [aman-dureja] #264
- Fix molpay and citrus tests [aman-dureja] #264

### Version 2.6.1 (Sep 7, 2017)
- Fix PayTM checksum generation [christianblais] #262

### Version 2.6.0 (Aug 29, 2017)
- Rails 5.1 compatibility [eitoball, patientdev] #245
- Update paydollar URLs [SimonLeungAPHK] #228
- Fixed compatibility between RubyMoney/money and Shopify/money gems [elfassy] #246
- Fixed calling Mollie with extra parameters [edwinv] #247
- Stop hiding JSON parse errors for Bitpay [bdewater] #251
- Do not send locale parameter to Sagepay [pi3r] #258
- Updats Skrill URL [sergey-alekseev ] #259
- Changed PayTM integration [Mohit-Aggarwal1] #260

### Version 2.5.0 (April 12, 2017)
- corrected zip parameter to from zip to zipcode
- [Realex] guard against nil when extracting AVS code
- only use fields that start with `x_` to generate the signature
- bump active_utils version 3.3.0

### Version 2.4.0 (March 7, 2017)
- Fixed use of decimal instead of float
- Fixed use Money gem
- Fixed sanitize of the phone field for payu_in
- Added Paytm
- Updated dependency on nokogiri 1.6

### Version 2.3.0 (February 8, 2016)
- Release 2.3.0

### Version 2.2.0 (October 14, 2015)
- Bump active_utils dependency. [lucasuyezu]

### Version 2.1.0 (January 16, 2015)

- **Change:** network exceptions now use ActiveUtils instead of ActiveMerchant as namespace,
  e.g. `ActiveUtils::ConnectionError` instead of `ActiveMerchant::ConnectionError`. [wvanbergen]
- Bump active_utils and active_support dependencies. [wvanbergen]
- Bump test dependencies. [wvanbergen]

### Version 2.0.1 (June 6, 2014)

- Configured ShipIt for deploys to RubyGems [bslobodin]

### Version 2.0.0 (June 4, 2014)

- Extracted from ActiveMerchant [ntalbott]
