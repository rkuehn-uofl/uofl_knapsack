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
    ['decade_sim', { label: 'Decade', limit: 5 }],
    ['creator_sim', { label: 'Creator', limit: 5 }],
    ['contributor_sim', { label: 'Contributor', limit: 5 }],
    ['object_type_sim', { label: 'Object type', limit: 5 }],
    ['resource_type_sim', { label: 'Resource type', limit: 5 }]
  ].freeze

  # Which of the FACETS above also surface in the "Attribute" pulldown on
  # /advanced. Everything in FACETS still renders as a sidebar facet on
  # regular search/browse -- BlacklightAdvancedSearch separately keys off
  # facet_fields[...].include_in_advanced_search (see
  # blacklight_advanced_search's #facet_field_names_for_advanced_search) to
  # decide what appears on the advanced search page specifically.
  ADVANCED_SEARCH_FACETS = %w[
    member_of_collections_ssim county_sim city_sim neighborhood_sim
    street_sim region_sim location_sim object_type_sim resource_type_sim
  ].freeze

  # Which config.search_fields show up in the field pulldown on /advanced
  # (BlacklightAdvancedSearch#search_fields_for_advanced_search, same
  # include_in_advanced_search mechanism as facets above). Order here is the
  # display order, since Blacklight renders the pulldown in config insertion
  # order and CatalogController#configure_blacklight defines all_fields,
  # contributor, creator, title, description, subject in that order already;
  # people_represented and story are new fields added below.
  ADVANCED_SEARCH_FIELDS = %w[
    all_fields contributor creator title description subject
    people_represented story
  ].freeze

  def configure_uofl_facets
    configure_blacklight do |config|
      config.facet_fields.clear

      FACETS.each do |field, options|
        config.add_facet_field field, **options
      end

      config.facet_fields.each do |key, field|
        field.include_in_advanced_search = ADVANCED_SEARCH_FACETS.include?(key)
      end

      config.add_facet_fields_to_solr_request!
    end
  end

  def configure_uofl_search_fields
    configure_blacklight do |config|
      # Not defined by CatalogController's own configure_blacklight block --
      # add them so they can appear in the advanced search field pulldown.
      # Guarded because in development this file is reloaded (not just
      # required once) on every request; add_search_field raises if the key
      # is already registered.
      unless config.search_fields.key?('people_represented')
        config.add_search_field('people_represented') do |field|
          field.label = 'People'
          solr_name = 'people_represented_tesim'
          field.solr_local_parameters = { qf: solr_name, pf: solr_name }
        end
      end

      unless config.search_fields.key?('story')
        config.add_search_field('story') do |field|
          field.label = 'Story'
          solr_name = 'story_tesim'
          field.solr_local_parameters = { qf: solr_name, pf: solr_name }
        end
      end

      config.search_fields.each do |key, field|
        field.include_in_advanced_search = ADVANCED_SEARCH_FIELDS.include?(key)
      end
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

  # hyrax-webapp/app/controllers/catalog_controller.rb sets hl.fl to every qf
  # field (via omission -- Solr defaults hl.fl to qf) with hl.snippets=30 and
  # hl.maxAnalyzedChars=5_100_000. Measured cost: on a search matching several
  # large scanned documents, highlighting alone added tens of ms per request,
  # most of it spent analyzing fields nothing reads. The only feature that
  # consumes highlight output is the "jump to the matching page" deep link
  # (shared_search_helper.rb / _thumbnail_list_default.html.erb), which reads
  # exactly one field -- config.iiif_search[:full_text_field], i.e.
  # all_text_tsimv -- and only checks for presence of a match, not snippet
  # count. Narrowing hl.fl to that field and cutting hl.snippets removes
  # wasted work with no visible effect. hl.maxAnalyzedChars is capped well
  # above the largest all_text field we've seen (~740K chars) so no document
  # loses the deep link.
  #
  # Applied directly to both controllers for the same reason as
  # configure_uofl_index_fields above -- Hyrax::CollectionsController's
  # blacklight_config is a copy taken at gem-autoload time, not a live
  # reference back to CatalogController's.
  def self.configure_uofl_solr_highlighting(klass)
    klass.configure_blacklight do |config|
      config.default_solr_params = config.default_solr_params.merge(
        "hl.fl": klass.blacklight_config.iiif_search[:full_text_field],
        "hl.snippets": 3,
        "hl.maxAnalyzedChars": 2_000_000
      )
    end
  end
end

# Catalog pages need the active home theme in their view path so shared partials
# such as /masthead and /controls resolve to the tenant's themed versions.
CatalogController.include(Hyku::HomePageThemesBehavior) unless CatalogController < Hyku::HomePageThemesBehavior
CatalogController.singleton_class.prepend(CatalogControllerDecorator)
CatalogController.configure_uofl_facets
CatalogController.configure_uofl_search_fields
CatalogControllerDecorator.configure_uofl_index_fields(CatalogController)
CatalogControllerDecorator.configure_uofl_index_fields(Hyrax::CollectionsController)
CatalogControllerDecorator.configure_uofl_solr_highlighting(CatalogController)
CatalogControllerDecorator.configure_uofl_solr_highlighting(Hyrax::CollectionsController)
