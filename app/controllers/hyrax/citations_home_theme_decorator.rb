# frozen_string_literal: true

# UOFL OVERRIDE: Hyrax::CitationsController (/works/:id/citation,
# /files/:id/citation) never loaded the active home theme, so those pages fell
# back to the stock masthead instead of the UofL one. Scope theme injection to
# its public `work`/`file` actions, same as Hyrax::WorksHomeThemeDecorator
# does for `show`.
module Hyrax
  module CitationsHomeThemeDecorator
    extend ActiveSupport::Concern

    include Hyku::HomePageThemesBehavior

    prepended do
      skip_around_action :inject_theme_views, raise: false
      around_action :inject_theme_views, only: %i[work file]
    end
  end
end

Hyrax::CitationsController.prepend(Hyrax::CitationsHomeThemeDecorator) unless Hyrax::CitationsController < Hyrax::CitationsHomeThemeDecorator
