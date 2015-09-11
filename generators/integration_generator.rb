require "thor/group"

class IntegrationGenerator < Thor::Group
  include Thor::Actions

  argument :name
  class_option :destroy, :type => :boolean, :desc => "Destroys rather than generates the gateway"

  source_root File.expand_path("..", __FILE__)

  def initialize(*args)
    super
  rescue Thor::InvocationError
    at_exit{print self.class.help(shell)}
    raise
  end

  def generate
    template "templates/integration.rb", "#{lib}.rb"

    template "templates/module_test.rb", "#{test_dir}/#{identifier}/#{identifier}_module_test.rb"
    template "templates/helper_test.rb", "#{test_dir}/#{identifier}/#{identifier}_helper_test.rb"
    template "templates/notification_test.rb", "#{test_dir}/#{identifier}/#{identifier}_notification_test.rb"
  end

  protected

  def template(source, dest)
    if options[:destroy]
      remove_file dest
    else
      super
    end
  end

  def identifier
    @identifier ||= class_name.gsub(%r{([A-Z])}){|m| "_#{$1.downcase}"}.sub(%r{^_}, "")
  end

  def class_name
    @class_name ||= name.gsub(%r{(^[a-z])|_([a-zA-Z])}){|m| ($1||$2).upcase}
  end

  def lib
    "lib/offsite_payments/integrations/#{identifier}"
  end

  def test_dir
    "test/unit/integrations"
  end
end
