# frozen_string_literal: true

# UOFL OVERRIDE: Hyrax::PagesController (hyrax-webapp) includes
# Hyku::HomePageThemesBehavior unscoped, so the themed masthead (built for
# the public homepage/hero) also gets injected on the admin `edit`/`update`
# actions under Configuration > Pages, breaking the dashboard layout. Scope
# theme injection to the public `show` action only, same as
# Hyrax::WorksHomeThemeDecorator does for work/collection controllers.
module Hyrax
  module PagesHomeThemeDecorator
    extend ActiveSupport::Concern

    include Hyku::HomePageThemesBehavior

    prepended do
      skip_around_action :inject_theme_views, raise: false
      around_action :inject_theme_views, only: :show
    end
  end
end

Hyrax::PagesController.prepend(Hyrax::PagesHomeThemeDecorator) unless Hyrax::PagesController < Hyrax::PagesHomeThemeDecorator
