# Contributing guidelines

We gladly accept new gateways or bugfixes to this library. Please read the guidelines for reporting issues and submitting pull requests below.

### Reporting issues

- Please make clear in the subject what gateway the issue is about.
- Include the version of OffsitePayments, Ruby, ActiveSupport, and Nokogiri you are using.

### Pull request guidelines

1. [Fork it](http://github.com/activemerchant/offsite_payments/fork) and clone your new repo
2. Create a branch (`git checkout -b my_awesome_feature`)
3. Commit your changes (`git add my/awesome/file.rb; git commit -m "Added my awesome feature"`)
4. Push your changes to your fork (`git push origin my_awesome_feature`)
5. Open a [Pull Request](https://github.com/shopify/offsite_payments/pulls)

The most important guidelines:

- All new integrations must have unit tests and functional remote tests.
- Your code should support all the Ruby versions and ActiveSupport versions we have enabled on Travis CI.
- No new gem dependencies will be accepted.
- **XML**: use Nokogiri for generating and parsing XML.
- **JSON**: use `JSON` in the standard library to parse and generate JSON.
- **HTTP**: use `ActiveUtils::PostsData` to do HTTP requests.
- Do not update the CHANGELOG, or the `OffsitePayments::VERSION` constant.

### Placement within Shopify

The addition of your payment integration to offsite_payments does not guarantee placement within Shopify. In order to have your gateway considered, please send an email to payment-integrations@shopify.com with **Offsite_Payment Integration** in the subject. Be sure to include:

1. Name, URL & description of the payment provider you wish to integrate
2. Markets served by this integration
3. List of major supported payment methods
4. Your most recent Certificate of PCI Compliance

### Releasing

1. Check the [semantic versioning page](http://semver.org) for info on how to version the new release.
2. Update the `OffsitePayments::VERSION` constant in **lib/offsite_payments/version.rb**.
3. Add a `CHANGELOG` entry for the new release with the date
4. Run `bundle install` and commit the changes you've made.
5. Tag the release commit on GitHub: `bundle exec rake tag_release`
6. Release the gem to rubygems using ShipIt
