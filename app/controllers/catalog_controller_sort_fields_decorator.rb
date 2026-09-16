# frozen_string_literal: true

# UOFL OVERRIDE: replace the default Relevance/Title/Author/Published
# Date/Upload Date sort pulldown on /catalog with a smaller, UofL-specific
# set -- but only for the uofl theme, so any other tenant/theme sharing this
# codebase keeps Blacklight/Hyrax's stock sort fields.
#
# "Item Number" sorts on source_identifier_ssi, a field populated directly by
# ResourceIndexerDecorator (app/indexers/resource_indexer_decorator.rb) rather
# than through the M3/flexible-schema profile -- see that file for why.
#
# This can't be a one-time class-level `configure_blacklight` call like
# CatalogControllerDecorator's facets/search-fields customizations (applied
# unconditionally at boot in catalog_controller_decorator.rb): which theme is
# active isn't known until a request resolves the current tenant
# (ApplicationController#home_page_theme reads current_account), so the
# guard has to run per-request instead. Blacklight::Configurable's instance
# method already hands each controller instance its own deep copy of the
# class-level config the first time it's touched
# (`@blacklight_config ||= self.class.blacklight_config.deep_copy`), so
# reconfiguring `blacklight_config` here in a before_action only affects the
# current request/tenant and never leaks into what other tenants/themes see.
module CatalogControllerSortFieldsDecorator
  extend ActiveSupport::Concern

  included do
    before_action :apply_uofl_sort_fields
  end

  private

  def apply_uofl_sort_fields
    return unless home_page_theme == 'uofl'

    blacklight_config.configure do |config|
      config.sort_fields.clear

      config.add_sort_field "score desc, #{self.class.uploaded_field} desc", label: "Relevance"
      config.add_sort_field "#{self.class.title_field} desc", label: "Title ▼"
      config.add_sort_field "#{self.class.title_field} asc", label: "Title ▲"
      config.add_sort_field "#{self.class.uploaded_field} desc", label: "Date Uploaded ▼"
      config.add_sort_field "#{self.class.uploaded_field} asc", label: "Date Uploaded ▲"
      config.add_sort_field "#{self.class.modified_field} desc", label: "Date Modified ▼"
      config.add_sort_field "#{self.class.modified_field} asc", label: "Date Modified ▲"
      config.add_sort_field "source_identifier_ssi asc", label: "Item Number"
    end
  end
end

CatalogController.include(CatalogControllerSortFieldsDecorator)
