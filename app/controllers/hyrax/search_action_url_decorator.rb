# frozen_string_literal: true

# UOFL OVERRIDE NEW FILE: Hyrax::CollectionsController, GenericWorksController,
# etc. all live inside the isolated Hyrax engine. Blacklight::Controller's
# default #search_action_url builds facet/filter links with a bare
# `search_catalog_url(...)` call - and from inside an isolated engine
# controller that doesn't resolve to the host app's /catalog route. Instead
# Rails matches it against an unrelated route in the engine's own route set
# (whatever happens to accept the leftover options as query params), producing
# broken links like "/files/:id?controller=catalog&action=index&f[...]=...".
# Clicking through one of those on a collection's (or work's) show page 500s
# with "undefined method `collection_path' for ActionDispatch::Routing::RoutesProxy"
# once Hyrax's breadcrumb code (main_app.polymorphic_path(presenter)) runs on
# the resulting page. This is what breaks every facet link in the shared
# "Browse"/"Filter" drawer (the header's filter drawer, now rendered on every
# public page - see catalog/_search_form) whenever it's shown on a collection
# or work show page instead of the real catalog search results page.
#
# Force it through main_app explicitly, mirroring Hyrax's own safe
# `link_to_facet` helper (Hyrax::HyraxHelperBehavior#link_to_facet).
module Hyrax
  module SearchActionUrlDecorator
    def search_action_url(options = {})
      options = options.to_h if options.is_a?(Blacklight::SearchState)
      main_app.search_catalog_url(options.except(:controller, :action))
    end
  end
end

[
  Hyrax::CollectionsController,
  Hyrax::EtdsController,
  Hyrax::FileSetsController,
  Hyrax::GenericWorksController,
  Hyrax::ImagesController,
  Hyrax::OersController,
  Hyrax::TextsController
].each do |controller|
  controller.prepend(Hyrax::SearchActionUrlDecorator) unless controller < Hyrax::SearchActionUrlDecorator
end
