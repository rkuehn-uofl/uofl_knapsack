# frozen_string_literal: true

# UOFL OVERRIDE: hyrax-webapp/config/locales/blacklight.en.yml hardcodes
# blacklight.search.fields.facet.publisher_sim => "Publisher", and
# Blacklight::Configuration::Field#display_label checks that exact i18n key
# BEFORE ever consulting a field's configured `label:` (see
# lib/blacklight/configuration/field.rb#display_label) -- so
# label: 'Repository' set in catalog_controller_search_fields_decorator.rb
# has no visible effect on its own, wherever that facet legitimately shows
# (only /advanced -- see that file for why it's hidden everywhere else).
#
# Tried overriding via a config/locales/*.yml file in this engine first
# (HykuKnapsack::Engine is meant to load its own locales with higher
# precedence than hyrax-webapp's -- see Engine.load_translations!) and via
# I18n.backend.store_translations directly in the decorator -- neither
# stuck, because HykuKnapsack::Engine's own after_initialize hook re-runs
# load_translations! (which calls I18n.backend.reload!, discarding any
# in-memory-only translations) at a point later in boot than our decorator
# file's to_prepare-triggered code. Overriding the helper method that reads
# the label sidesteps that ordering fight entirely.
module ConfigurationHelperBehaviorDecorator
  def facet_field_label(field)
    return 'Repository' if field.to_s == 'publisher_sim'

    super
  end
end

Blacklight::ConfigurationHelperBehavior.prepend(ConfigurationHelperBehaviorDecorator)
