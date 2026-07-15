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

  # Same predicate as CatalogController#render_in_tenant?, but expressed as a
  # proc instead of a `:render_in_tenant?` method reference, so it doesn't
  # depend on the rendering controller defining that method.
  #
  # This matters because the collection show page's gallery-view metadata
  # (each work's Description/Subject/etc. under its title) is rendered via
  # Blacklight::ShowPresenter -- i.e. `config.show_fields`, not
  # `config.index_fields` -- because Blacklight's view_config resolution keys
  # off `action_name` ("show" for Hyrax::CollectionsController#show) rather
  # than the actual list/gallery view type. None of catalog_controller.rb's
  # `add_show_field` calls carry an `if:` condition, so the site's Hidden
  # Index Fields setting was never actually consulted there.
  RENDER_IN_TENANT = lambda do |_context, field_config, _doc|
    hidden_fields = Site.account&.hidden_index_fields
    next true if hidden_fields.blank?

    human_field_name = field_config.key.split('_')[0..-2].join('_')
    hidden_fields.split(/\s*,\s*/).exclude?(human_field_name)
  end

  # UofL's accession/item number, populated by Bulkrax on import.
  #
  # Applied directly to both CatalogController and Hyrax::CollectionsController
  # (rather than relying on Hyrax::CollectionsController#copy_blacklight_config_from)
  # because CollectionsController lives in the Hyrax gem and only copies
  # CatalogController's config once, at first autoload -- which in practice can
  # happen before this decorator's customizations are guaranteed to have run.
  #
  # Applies RENDER_IN_TENANT to both index_fields and show_fields so the Hidden
  # Index Fields setting works regardless of which config Blacklight consults.
  def self.configure_uofl_index_fields(klass)
    klass.configure_blacklight do |config|
      config.index_fields.each_value { |field| field.if = RENDER_IN_TENANT }
      config.show_fields.each_value { |field| field.if = RENDER_IN_TENANT }

      unless config.index_fields.key?('source_identifier_tesim')
        config.add_index_field 'source_identifier_tesim', label: 'Item Number', if: RENDER_IN_TENANT
      end

      unless config.show_fields.key?('source_identifier_tesim')
        config.add_show_field 'source_identifier_tesim', label: 'Item Number', if: RENDER_IN_TENANT
      end
    end
  end
end

# Catalog pages need the active home theme in their view path so shared partials
# such as /masthead and /controls resolve to the tenant's themed versions.
CatalogController.include(Hyku::HomePageThemesBehavior) unless CatalogController < Hyku::HomePageThemesBehavior
CatalogController.singleton_class.prepend(CatalogControllerDecorator)
CatalogController.configure_uofl_facets
CatalogControllerDecorator.configure_uofl_index_fields(CatalogController)
CatalogControllerDecorator.configure_uofl_index_fields(Hyrax::CollectionsController)
