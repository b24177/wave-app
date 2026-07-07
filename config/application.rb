require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)
if ENV['RAILS_ENV']!="production"
  Dotenv::Railtie.load
end

module Wave
  class Application < Rails::Application
    config.generators do |generate|
      generate.assets false
      generate.helper false
      generate.test_framework :test_unit, fixture: false
    end
    # Initialize configuration defaults for Rails 7.0.
    config.load_defaults 7.0

    # Keep existing UJS-style remote form behavior to avoid UI regressions.
    config.action_view.form_with_generates_remote_forms = true

    # Avoid requiring Active Storage variant tracking migration during upgrade.
    config.active_storage.track_variants = false

    # Switch cache entry format to Rails 7.
    config.active_support.cache_format_version = 7.0

    # Disable deprecated implicit #to_s conversions.
    config.active_support.disable_to_s_conversion = true

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
  end
end
