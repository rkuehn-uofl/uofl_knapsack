# frozen_string_literal: true

# UOFL OVERRIDE: CatalogController and Hyrax::HomepageController both include
# Hydra::Catalog (which pulls in Blacklight::Catalog), but Hyrax::CollectionsController
# never has. That leaves facet_limit_for - used by Blacklight's facet_paginator/
# render_facet_limit chain - unavailable as a helper method here, so the shared
# hyrax/homepage/facets partial (rendered in the header's filter drawer on every
# page, see catalog/_search_form) raises NoMethodError as soon as a collection's
# show page actually has facet values to render.
#
# NOTE: we intentionally do NOT `include Hydra::Catalog` here - it pulls in
# Blacklight::Searchable#search_service, which would shadow
# Hyrax::CollectionsControllerBehavior's own search_service (the one that scopes
# curation_concern's lookup to this single collection via SingleCollectionSearchBuilder).
# Ruby's include order means a later include wins, so that swap happens silently and
# curation_concern starts resolving to an arbitrary public document instead of this one.
# facet_limit_for's implementation is copied verbatim from Blacklight::Catalog.
module Hyrax
  module CollectionsControllerDecorator
    extend ActiveSupport::Concern

    included do
      helper_method :facet_limit_for if respond_to?(:helper_method)
    end

    # @see Blacklight::Catalog#facet_limit_for
    def facet_limit_for(facet_field)
      facet = blacklight_config.facet_fields[facet_field]
      return if facet.blank?

      if facet.limit && @response && @response.aggregations[facet.field]
        limit = @response.aggregations[facet.field].limit

        if limit.nil?
          facet.limit if facet.limit != true
        elsif limit == -1
          nil
        else
          limit.to_i - 1
        end
      elsif facet.limit
        facet.limit == true ? Blacklight::Catalog::DEFAULT_FACET_LIMIT : facet.limit
      end
    end
  end
end

Hyrax::CollectionsController.include Hyrax::CollectionsControllerDecorator
