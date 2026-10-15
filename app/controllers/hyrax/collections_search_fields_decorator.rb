# frozen_string_literal: true

# UOFL OVERRIDE: make the "Search works in this collection" box (cq) on both
# /collections/:id and /dashboard/collections/:id search the same fields as
# /catalog -- in particular source_identifier_tesim (Item number) and the
# other UofL M3 properties.
#
# CatalogController includes Hyrax::FlexibleCatalogBehavior, whose
# #initialize runs load_flexible_schema and appends every stored_searchable
# M3 property to CatalogController's all_fields qf. The collection
# controllers don't include that behavior; they took a one-time deep copy of
# CatalogController's blacklight_config (copy_blacklight_config_from) at class
# load, before any CatalogController was instantiated, so their all_fields qf
# is frozen at hyrax-webapp's static list and never picks up M3 fields.
# Hyrax::Collections::CollectionMemberSearchService uses the controller's
# blacklight_config, so the cq search silently skips those fields.
#
# Before each request, refresh CatalogController's M3 fields (the same call
# its own #initialize makes, so profile changes are picked up just as they
# are on /catalog) and copy its all_fields qf over.
module Hyrax
  module CollectionsSearchFieldsDecorator
    extend ActiveSupport::Concern

    included do
      before_action :sync_all_fields_qf_from_catalog
    end

    private

    def sync_all_fields_qf_from_catalog
      CatalogController.load_flexible_schema if CatalogController.respond_to?(:load_flexible_schema)

      catalog_qf = CatalogController.blacklight_config.search_fields['all_fields']&.solr_parameters&.dig(:qf)
      field = blacklight_config.search_fields['all_fields']
      return if catalog_qf.blank? || field.nil?

      field.solr_parameters[:qf] = catalog_qf.dup
    end
  end
end

Hyrax::CollectionsController.include Hyrax::CollectionsSearchFieldsDecorator
Hyrax::Dashboard::CollectionsController.include Hyrax::CollectionsSearchFieldsDecorator
