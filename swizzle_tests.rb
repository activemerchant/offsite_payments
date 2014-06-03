require "fileutils"
require "pathname"

root = Pathname.new("test/unit/integrations/").expand_path
base_test = Pathname.new(ARGV[0] || abort).expand_path
name = base_test.basename(".rb").to_s[/^(\w+)_module_test/, 1]
destination = (root + name)

destination.mkpath
FileUtils.mv(base_test, destination) if base_test.exist?

helper = (root + "helpers/#{name}_helper_test.rb")
FileUtils.mv(helper, destination) if helper.exist?

notification = (root + "notifications/#{name}_notification_test.rb")
FileUtils.mv(notification, destination) if notification.exist?

ret = (root + "returns/#{name}_return_test.rb")
FileUtils.mv(ret, destination) if ret.exist?
