if defined?(Webpacker::Configuration)
  Webpacker::Configuration.class_eval do
    private

    def defaults
      @defaults ||= begin
        shakapacker_spec = Gem.loaded_specs['shakapacker'] || Gem.loaded_specs['webpacker']
        defaults_yaml_path = File.join(
          shakapacker_spec.full_gem_path,
          'lib',
          'install',
          'config',
          'webpacker.yml'
        )

        yaml_content = File.read(defaults_yaml_path)
        yaml = Psych.safe_load(yaml_content, aliases: true)

        HashWithIndifferentAccess.new(yaml[env])
      end
    end
  end
end
