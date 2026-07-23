# frozen_string_literal: true

# UOFL OVERRIDE: UofL Theme
#
# Loads the human-curated "Featured Theme" carousel groups for the homepage
# from config/uofl_featured_carousel_themes.yml. Each group is one theme -
# a title/description/search_path shown once - plus a list of pictures that
# cycle through it. Only the group named by the file's `active_group` key
# is shown on the homepage, so a curator can swap the whole carousel by
# changing that one value. All groups (not just the active one) are
# available via `.for_group`/`.group_names`, which power the signed-in-only
# carousel preview page (UoflFeaturedCarouselPreviewsController) that lets
# a curator check a new group before making it active. See the config file
# for the entry format and instructions for adding a group; see
# UoflHomepageHelper#uofl_featured_carousel_slides for how a group's
# pictures are resolved into carousel slide data.
class UoflFeaturedCarouselThemes
  CONFIG_PATH = HykuKnapsack::Engine.root.join('config', 'uofl_featured_carousel_themes.yml')

  def self.all
    for_group(active_group)
  end

  def self.active_group
    config[:active_group]
  end

  def self.group_names
    groups.keys
  end

  def self.for_group(name)
    groups[name&.to_sym]
  end

  def self.groups
    config[:groups] || {}
  end

  def self.config
    YAML.safe_load_file(CONFIG_PATH, symbolize_names: true) || {}
  end
end
