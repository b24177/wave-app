require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)
if ENV['RAILS_ENV']!="production"
  Dotenv::Railtie.load
end

def skip_rspotify_auth?
  # Skip if CLIENT_ID/SECRET are missing or placeholder values
  client_id = ENV['CLIENT_ID'].to_s.strip
  client_secret = ENV['CLIENT_SECRET'].to_s.strip
  
  return true if client_id.empty? || client_secret.empty?
  return true if client_id.include?('your_') || client_secret.include?('your_')
  return true if client_id == 'demo' || client_secret == 'demo'
  
  # Skip for CLI/DB/test tasks
  return true if ARGV.any? { |arg| arg.start_with?('db:', 'assets:', 'test', 'spec') }
  return true if File.basename($PROGRAM_NAME) =~ /^(rake|spring|bundle)$/
  return true if ARGV.include?('server') || ARGV.include?('s')
  false
end

begin
  if ENV['CLIENT_ID'].present? && ENV['CLIENT_SECRET'].present? && !skip_rspotify_auth?
    RSpotify::authenticate(ENV.fetch('CLIENT_ID'), ENV.fetch('CLIENT_SECRET'))
  end
rescue RestClient::BadRequest, RestClient::Unauthorized => e
  # Spotify auth failed, likely due to invalid credentials in development
  # This is non-fatal; the app can still run
  Rails.logger.warn("Spotify authentication failed: #{e.message}. Continuing without Spotify integration.")
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
