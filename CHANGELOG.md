# Offsite Payments CHANGELOG

### version 3.0.1 (September 24, 2024)
- Update shopify-money dependency to >= 2.0

### version 3.0.0 (September 24, 2024)
This version officially deprecates this gem. It is no longer maintained and should not be used.

- Update ruby test targets to 3.2 and 3.3
- Require rails v7.2
- Require shopify-money gem, no longer support other money gem.

### version 2.7.28 (February 11, 2021)
- [Realex] #351
  - Regex updates for address and city
  - TR-86: [29RnExPb]: regex updates - minor correction
  - Removed the BILLING_CODE field when the country is not US, CA or GB
  - added two new characters to the REGEXES for street and city fields, removed the parantheeses on these REGEXES and removed the non allowed characters from the BILLING_CODE field

### version 2.7.27 (January 21, 2021)
- [Gestpay] Update service_url #352
- Specify money gem version #353

### version 2.7.26 (January 06, 2021)
- Exactly the same as 2.7.25, just adding a missing Gemfile.lock file

### version 2.7.25 (January 06, 2021)
- [REALEX] Improvements, validations and formatted phone number [ahumulescu, tjozwik, apetrovici] #348
- Change to use `String#start_with?` instead of `String#starts_with?`. [akiko-pusu] #342

### version 2.7.24 (March 30, 2020)
- Add ``allowed_push_host` to gemspec [pi3r]`

### version 2.7.23 (March 30, 2020)
- Test newer rubies and railses [byroot] #342

### version 2.7.22 (March 10, 2020)
- Bump rake from 12.3.2 to 13.0.1 [dependabot] #340
- Remove special subunit case for HUF in universal integration [krispenney] #341
- Bump nokogiri from 1.10.5 to 1.10.8 [dependabot] #339
- Added quickpay which already has code for it [espen] #85
- Added support for Quickpay v10 [calvincorreli] #205
- Bump loofah from 2.2.3 to 2.3.1 [dependabot] #336
- Bump rack from 2.0.7 to 2.0.8 [dependabot] #338

### version 2.7.21 (Sept 23, 2019)
- Various updates to the Realex integration [pi3r] #324
- [Realex] Use application_id instead of hardcoded Shopify [pi3r] #334

### version 2.7.20 (Sept 16, 2019)
- [Bitpay] api version tracking [thejoshualewis] #331

### version 2.7.19 (July 11, 2019)
- [Bitpay] Only compare transaction_id/status while acknowledging [pi3r] #330

### version 2.7.18 (July 11, 2019)
- [Bitpay] Fixes an issue where notification couldn't be acknowledged [pi3r] #329

### version 2.7.17 (July 10, 2019)
- [BitPay] Read information from the `data` key present in the payload instead of root [pi3r] #328

### version 2.7.16 (June 26, 2019)
- [BitPay] properly call `v2_api_token?` on the BitPay module [pi3r] #325
- [BitPay] properly fetch the invoice id after creation [pi3r] #325
- Remove support for Ruby 2.3/2.2 (they are EOL) [pi3r]

### version 2.7.15 (June 18, 2019)
- Update URL for Paytm [AnnaGyergyai] #315

### version 2.7.14 (June 18, 2019)
- [Bitpay] Include basic auth only when the api isn't v2 [anbugal] #323

### version 2.7.13 (May 22, 2019)
- [BitPay] Add token to payload while creating the invoice [pi3r] #321

### version 2.7.12 (May 13, 2019)

- [BitPay] Use v2 api urls when the api token is of type v2 [pi3r] #319
- Fix CVE-2019-5418, CVE-2018-14404 [pi3r] #317

### version 2.7.11 (December 14, 2018)
- Add `TXNDATETIME` to the whitelist of params to use for checksum verification [pi3r] #308

### version 2.7.10 (November 26, 2018)
- Quickpay callback includes acquirer param and must be checked with md5secret from options [espen] #72
- map payu_in pg status pending as Failed [GeminPatel] #306

### version 2.7.9 (November 26, 2018)
- Update rack and loofah to fix security issues [pi3r] #307

### version 2.7.8 (October 11, 2018)
- remove credential2 and access key from citrus helper fields [elfassy] #304

### version 2.7.7 (September 13, 2018)
- Update sprockets to new versions [Girardvjonathan] #302

### version 2.7.6 (August 23, 2018)
- Update Paytm test and production urls [rahul7verma] #301

### Version 2.7.5 (June 14, 2018)
- add failure reasons for Moneybookers (Skrill) integration [dhalai] #263

### Version 2.7.4 (June 13, 2018)
- Update Mollie iDEAL & MisterCash handling of querystring [joshnuss] #299

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
