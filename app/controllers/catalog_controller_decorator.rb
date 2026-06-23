# frozen_string_literal: true

# UOFL OVERRIDE: customize public catalog facet order and labels.

module CatalogControllerDecorator
  FACETS = [
    ['member_of_collections_ssim', { label: 'Collection', limit: 5 }],
    ['subject_sim', { label: 'Subject', limit: 5 }],
    ['people_represented_sim', { label: 'People', limit: 5 }],
    ['county_sim', { label: 'County', limit: 5 }],
    ['city_sim', { label: 'City', limit: 5 }],
    ['neighborhood_sim', { label: 'Neighborhood', limit: 5 }],
    ['street_sim', { label: 'Street', limit: 5 }],
    ['region_sim', { label: 'Region', limit: 5 }],
    ['decade_sim', { label: 'Decade', limit: 5 }],
    ['creator_sim', { label: 'Creator', limit: 5 }],
    ['contributor_sim', { label: 'Contributor', limit: 5 }],
    ['object_type_sim', { label: 'Object Type', limit: 5 }],
    ['resource_type_sim', { label: 'Media Type', limit: 5 }]
  ].freeze

  def configure_uofl_facets
    configure_blacklight do |config|
      config.facet_fields.clear

      FACETS.each do |field, options|
        config.add_facet_field field, **options
      end

      config.add_facet_fields_to_solr_request!
    end
  end
end

# Catalog pages need the active home theme in their view path so shared partials
# such as /masthead and /controls resolve to the tenant's themed versions.
CatalogController.include(Hyku::HomePageThemesBehavior) unless CatalogController < Hyku::HomePageThemesBehavior
CatalogController.singleton_class.prepend(CatalogControllerDecorator)
CatalogController.configure_uofl_facets
