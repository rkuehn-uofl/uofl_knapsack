# frozen_string_literal: true

# UOFL OVERRIDE: control the exact order of the "Attribute" pulldown on
# /advanced. BlacklightAdvancedSearch::AdvancedHelperBehavior#facet_field_names_for_advanced_search
# (see app/controllers/catalog_controller_search_fields_decorator.rb) derives
# its list by filtering config.facet_fields, which is a Hash -- so its order
# is whatever order those facets happened to be registered in. Collection
# through "Resource type" come from CatalogControllerDecorator::FACETS
# (loaded first); "Location", "Region", and "Repository" are registered
# afterward, in our own decorator, so they always land at the end,
# regardless of what order we add them in. There's no way to interleave a
# later Hash insertion into an earlier position without fully rebuilding
# the Hash -- which would mean reordering (or duplicating)
# CatalogControllerDecorator::FACETS, the one thing we've deliberately kept
# hands-off. Overriding this method with an explicit order sidesteps that
# entirely: it doesn't matter what order the underlying facet_fields Hash
# has them in, only that each key exists there.
module AdvancedHelperBehaviorDecorator
  ADVANCED_SEARCH_FACET_ORDER = %w[
    member_of_collections_ssim county_sim city_sim neighborhood_sim
    street_sim location_sim region_sim object_type_sim resource_type_sim
    publisher_sim
  ].freeze

  def facet_field_names_for_advanced_search
    @facet_field_names_for_advanced_search ||=
      ADVANCED_SEARCH_FACET_ORDER.select { |key| blacklight_config.facet_fields.key?(key) }
  end
end

BlacklightAdvancedSearch::AdvancedHelperBehavior.prepend(AdvancedHelperBehaviorDecorator)
