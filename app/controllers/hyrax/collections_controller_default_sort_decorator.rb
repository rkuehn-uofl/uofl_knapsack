# frozen_string_literal: true

# UOFL OVERRIDE: make Relevance (the first sort field configured in
# CatalogControllerSortFieldsDecorator) the default sort on /collections/:id,
# matching /catalog -- the collection page has its own search box, so
# relevance-ranked results are what a search there should show.
#
# Hyku (hyrax-webapp) defaults this page to title_ssi asc instead, in both
# Hyrax::CollectionsControllerBehaviorDecorator#show (`params[:sort] ||= ...`)
# and Hyrax::Collections::CollectionMemberSearchServiceDecorator
# (`user_params[:sort] || ...`). Both only apply when params[:sort] is blank,
# so filling it in first is enough. This is prepended onto the
# CollectionsController class itself (rather than CollectionsControllerBehavior,
# where Hyku's decorator sits) so it runs ahead of Hyku's #show regardless of
# which decorator file loads first.
#
# By the time #show runs, CatalogControllerSortFieldsDecorator's before_action
# has already swapped in the UofL sort fields, so default_sort_field is the
# Relevance entry. Gated to the uofl theme like that decorator, so other
# tenants/themes keep Hyku's title default.
module Hyrax
  module CollectionsControllerDefaultSortDecorator
    def show
      params[:sort] ||= blacklight_config.default_sort_field&.key if home_page_theme == 'uofl'

      super
    end
  end
end

Hyrax::CollectionsController.prepend Hyrax::CollectionsControllerDefaultSortDecorator
