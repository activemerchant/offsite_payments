module OffsitePayments
  class Railtie < Rails::Railtie
    config.before_eager_load do
      config.eager_load_namespace << OffsitePayments
    end
  end
end
