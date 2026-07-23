# frozen_string_literal: true

# UOFL OVERRIDE: fix duplicate constraint chips (e.g. two identical
# "City > Louisville (Ky.)" chips) on search results reached from /advanced.
#
# BlacklightAdvancedSearch::RenderConstraintsOverride#render_constraints_filters
# (blacklight_advanced_search 7.0.0) predates Blacklight's own native
# handling of `f_inclusive` filters (Blacklight::SearchState::FilterField,
# now in Blacklight core -- see filter_field.rb#values, which already folds
# f_inclusive values into search_state.filters). That gem method calls
# `super` -- which, with the current Blacklight, already renders a
# constraint chip for every f_inclusive facet selection -- and then
# *additionally* re-renders the same filters again via its own legacy
# `advanced_query.filters` loop, producing a duplicate chip for every
# facet chosen on the advanced search page.
#
# Reopening (not prepending) the gem's module here so the redundant loop is
# fully replaced rather than layered on top of; `super` inside this method
# still resolves correctly at the view-helper include site to Blacklight's
# core (now f_inclusive-aware) implementation.
#
# Wrapped in a top-level module matching this filename (rather than reopening
# BlacklightAdvancedSearch::RenderConstraintsOverride directly at the file's
# top level): Zeitwerk eager-loads every app/**/*.rb file (triggered by
# RAILS_ENV=production, e.g. during `assets:precompile`) and requires each
# one to define the constant its path implies --
# render_constraints_override_decorator.rb must define
# ::RenderConstraintsOverrideDecorator, not reopen an unrelated existing
# constant. The module_eval below still reopens and redefines the method
# exactly as before, as a side effect of this file loading.
module RenderConstraintsOverrideDecorator
  BlacklightAdvancedSearch::RenderConstraintsOverride.module_eval do
    def render_constraints_filters(my_params = params)
      super(my_params)
    end
  end
end
