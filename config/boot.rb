ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'logger'
require 'bundler/setup' # Set up gems listed in the Gemfile.

# Fix Logger::Severity compatibility for Ruby 3.1
unless defined?(Logger::Severity)
  class Logger
    Severity = Module.new
    ::Logger::Severity.constants.each do |const|
      ::Logger::Severity.const_set(const, ::Logger.const_get(const))
    end
  end
end

require 'yaml'
class << YAML
  alias_method :__original_load_file, :load_file

  def load_file(path, **kwargs)
    __original_load_file(path, **kwargs)
  rescue Psych::BadAlias
    raise if kwargs.key?(:aliases)
    __original_load_file(path, **kwargs.merge(aliases: true))
  end
end

require 'bootsnap/setup' # Speed up boot time by caching expensive operations.
