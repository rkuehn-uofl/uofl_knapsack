# frozen_string_literal: true

# UOFL OVERRIDE: UofL Theme
#
# Loads the curator-picked "Popular Collections" entries for the masthead's
# Collections mega-menu from config/uofl_popular_collections.yml. Each entry
# is a `collection_id` (the collection's human-readable item number), an
# optional `collection_name` link-text override, and free-text `notes`. See
# the config file for the entry format, and
# UoflHomepageHelper#uofl_popular_collections for how entries are resolved
# into real collections.
class UoflPopularCollections
  CONFIG_PATH = HykuKnapsack::Engine.root.join('config', 'uofl_popular_collections.yml')

  # Entries with a blank `collection_id` are dropped, since there's nothing
  # to look up.
  def self.all
    Array(config[:collections]).filter_map do |entry|
      next unless entry.is_a?(Hash)

      collection_id = entry[:collection_id].to_s.strip
      next if collection_id.blank?

      { collection_id: collection_id, collection_name: entry[:collection_name].to_s.strip.presence }
    end
  end

  # A missing or malformed file loads as an empty config (see UoflYamlConfig).
  def self.config
    UoflYamlConfig.load(CONFIG_PATH)
  end

  # nil if the config file loads fine, otherwise what's wrong with it - shown
  # on the hero and carousel preview pages, since this has none of its own.
  def self.config_error
    UoflYamlConfig.error(CONFIG_PATH)
  end
end
