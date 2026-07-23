# frozen_string_literal: true

# UOFL OVERRIDE: customize which config.search_fields / config.facet_fields
# entries surface on the /advanced page, without touching the curated /catalog
# sidebar list in catalog_controller_decorator.rb
# (CatalogControllerDecorator::FACETS / #configure_uofl_facets).
#
# This deliberately lives in its own file so the two concerns can't collide:
# CatalogControllerDecorator owns the sidebar facets on /catalog, this owns
# what shows on /advanced.
#
# Filename matters: Rails loads app/**/*_decorator*.rb files in sorted
# order (see HykuKnapsack::Engine#to_prepare), and "catalog_controller_
# search_fields_decorator.rb" sorts after "catalog_controller_decorator.rb"
# alphabetically -- so this always runs after CatalogControllerDecorator has
# rebuilt config.facet_fields from FACETS, and this file's `.each` over
# config.facet_fields sees the real UofL facet set, not the pre-decorator
# hyrax-webapp defaults.
module CatalogControllerSearchFieldsDecorator
  # Field pulldown shown on /advanced (BlacklightAdvancedSearch's
  # #search_fields_for_advanced_search, used by
  # app/views/themes/uofl/advanced/_advanced_search_fields.html.erb, which
  # already calls that filtered helper).
  SEARCH_FIELD_KEYS = %w[
    all_fields contributor creator title description subject
    people_represented story
  ].freeze

  # Attribute pulldown shown on /advanced. See the comment on
  # app/views/themes/uofl/advanced/_advanced_search_facets_as_select.html.erb
  # -- it calls facet_field_names_for_advanced_search (filtered by this flag)
  # instead of the unfiltered facet_field_names, so this list -- and only
  # this list -- controls what shows there.
  FACET_FIELD_KEYS = %w[
    member_of_collections_ssim county_sim city_sim neighborhood_sim
    street_sim region_sim location_sim object_type_sim resource_type_sim
    publisher_sim
  ].freeze

  def configure_uofl_advanced_search
    configure_blacklight do |config|
      # Guarded because in development this file is reloaded (not just
      # required once) on every request; add_search_field/add_facet_field
      # raise if the key is already registered.
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
        field.include_in_advanced_search = SEARCH_FIELD_KEYS.include?(key)
      end

      # The base 'description' search field (hyrax-webapp/app/controllers/
      # catalog_controller.rb) already targets the right Solr field
      # (description_tesim, matching the M3 `description` property) but
      # hardcodes the label "Abstract or Summary" -- a mismatch with what
      # UofL wants shown here. Relabel only; leave its solr_parameters/
      # solr_local_parameters (the actual field targeted) untouched.
      if config.search_fields.key?('description')
        config.search_fields['description'].label = 'Description'
      end

      # "Repository" (publisher_sim), "Location" (location_sim), and
      # "Region" (region_sim) are advanced-search-only attributes -- none
      # is part of CatalogControllerDecorator::FACETS -- so each must be
      # registered here explicitly, WITH an `if` that always evaluates false:
      # Blacklight::FacetComponent#render? (used by every ordinary
      # facet-rendering surface, including the /catalog sidebar and the
      # homepage/collection "Browse" drawer) checks this and hides them
      # there. The /advanced facet-as-select partial doesn't check `if` at
      # all, so both still show there via
      # facet_field_names_for_advanced_search.
      #
      # This MUST happen here, unconditionally, on every to_prepare cycle
      # (i.e. before any request can be dispatched) rather than lazily or
      # only on AdvancedController: Hyrax::FlexibleCatalogBehavior
      # (included in CatalogController) auto-adds any M3 property marked
      # "facetable" -- "publisher", "location", and "region" all are -- to
      # whatever CatalogController-descended controller's blacklight_config
      # doesn't already have it, the moment that controller is
      # instantiated. In particular, Hyku's
      # Hyrax::HomepageController#search_service calls `CatalogController.new`
      # directly to fetch its config, which triggers exactly that add --
      # unsuppressed (and, for publisher_sim, mislabeled "Publisher" from a
      # hardcoded hyrax-webapp locale key; see
      # app/helpers/configuration_helper_behavior_decorator.rb for why the
      # label: below alone doesn't fix that) -- on every homepage request,
      # unless our own suppressed version is already registered first.
      # Registering all three here, guarded, guarantees that: to_prepare
      # always runs before the first request is dispatched, so this beats
      # every request-triggered auto-add to the punch.
      unless config.facet_fields.key?('publisher_sim')
        config.add_facet_field 'publisher_sim', label: 'Repository', limit: 5, if: ->(*) { false }
      end

      unless config.facet_fields.key?('location_sim')
        config.add_facet_field 'location_sim', label: 'Location', limit: 5, if: ->(*) { false }
      end

      unless config.facet_fields.key?('region_sim')
        config.add_facet_field 'region_sim', label: 'Region', limit: 5, if: ->(*) { false }
      end

      # Only flips a flag on facets that already exist -- this is the ONLY
      # thing consulted by
      # BlacklightAdvancedSearch::AdvancedHelperBehavior#facet_field_names_for_advanced_search,
      # so it's harmless everywhere else facet_fields gets rendered.
      config.facet_fields.each do |key, field|
        field.include_in_advanced_search = FACET_FIELD_KEYS.include?(key)
      end
    end
  end
end

CatalogController.singleton_class.prepend(CatalogControllerSearchFieldsDecorator)
CatalogController.configure_uofl_advanced_search

# The /advanced page is served by AdvancedController (from the
# blacklight_advanced_search gem), which subclasses CatalogController but
# takes its own one-time, disconnected deep copy of CatalogController's
# blacklight_config via `copy_blacklight_config_from` at class-definition
# time (see AdvancedController#blacklight_config /
# Blacklight::Configurable#copy_blacklight_config_from -- plain assignment,
# safe to repeat). That copy was made before this file's (and even
# catalog_controller_decorator.rb's) customizations ran, so without this
# re-sync /advanced silently keeps showing hyrax-webapp's base facets/fields
# forever, regardless of anything configured above or in
# catalog_controller_decorator.rb.
AdvancedController.copy_blacklight_config_from(CatalogController)

