# frozen_string_literal: true

# UOFL OVERRIDE: Register UofL work types and keep knapsack metadata schemas ahead of Hyku.
# Use this to override any Hyrax configuration from the Knapsack

Rails.application.config.after_initialize do
  Hyrax.config do |config|
    config.flexible = ActiveModel::Type::Boolean.new.cast(ENV.fetch('HYRAX_FLEXIBLE', 'false'))

    # Injected via `rails g hyrax:work_resource Text`
    config.register_curation_concern :text

    # Prepend to ensure knapsack profile is checked before the host app's profiles.
    config.schema_loader_config_search_paths.unshift(HykuKnapsack::Engine.root) \
      if config.respond_to?(:schema_loader_config_search_paths)

    # Keep redirect aliases off the knapsack's own routes (config/routes.rb).
    # A prefix only matches itself or "<prefix>/...", so /uofl_uv needs its own entry.
    if config.respond_to?(:reserved_redirect_prefixes)
      config.reserved_redirect_prefixes |= %w[
        /turnstile
        /uofl
        /uofl_uv
      ]
    end
  end

  # Work classes snapshot Hyrax.config.curation_concerns into valid_child_concerns when
  # they load, which under eager loading is before this block registers Text.
  HykuKnapsack::ReseedValidChildConcerns.call
end
