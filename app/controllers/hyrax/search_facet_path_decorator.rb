# frozen_string_literal: true

# UOFL OVERRIDE NEW FILE: every facet's "more »" link (the one that opens
# Blacklight's facet-values modal) is built from
# Blacklight::FacetFieldPresenter#modal_path, which calls
# Blacklight::Controller#search_facet_path. That method builds its URL with
# a bare `url_for(search_state.to_h.merge(action: "facet", ...))` -- no
# explicit `controller:` key -- so it resolves against whatever controller
# is currently rendering the facet partial. On CatalogController itself
# that's fine, since CatalogController genuinely has a `facet` action/route
# (/catalog/facet/:id). None of the controllers below do, though (Homepage
# only has root/`/homepage` -> #index; the isolated-engine work/collection
# controllers have no facet route either), so `url_for` can't match a real
# route for action: "facet" and instead falls back to the controller's own
# current route with the leftover options (action, id) dumped as query
# params -- e.g. "/homepage?id=subject_sim&locale=en" -- which just
# reloads that page's #index instead of opening the facet-values modal.
#
# This is the same class of bug already fixed once in this codebase for
# search_action_url (see search_action_url_decorator.rb, which forces
# search-form submission links through main_app's real CatalogController
# route for the same set of controllers, plus Hyrax::HomepageController's
# own copied-from-Hyrax override). search_facet_path is a separate method
# that fix doesn't touch, so the "more" modal link stayed broken. Same
# remedy: force it through main_app's real catalog#facet route.
module Hyrax
  module SearchFacetPathDecorator
    def search_facet_path(options = {})
      opts = search_state.to_h.merge(action: 'facet', only_path: true).merge(options).except(:page)
      # Leading slash required: these controllers live under the Hyrax
      # module (controller_path "hyrax/homepage", "hyrax/collections",
      # etc.), so url_for treats a bare "catalog" as relative to that
      # namespace and resolves it to the nonexistent "hyrax/catalog"
      # instead of the real top-level CatalogController.
      main_app.url_for(opts.merge(controller: '/catalog'))
    end
  end
end

[
  Hyrax::HomepageController,
  Hyrax::CollectionsController,
  Hyrax::EtdsController,
  Hyrax::FileSetsController,
  Hyrax::GenericWorksController,
  Hyrax::ImagesController,
  Hyrax::OersController,
  Hyrax::TextsController
].each do |controller|
  controller.prepend(Hyrax::SearchFacetPathDecorator) unless controller < Hyrax::SearchFacetPathDecorator
end
