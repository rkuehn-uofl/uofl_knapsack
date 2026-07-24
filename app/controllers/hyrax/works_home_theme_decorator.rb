# frozen_string_literal: true

# UOFL OVERRIDE: Resolve shared public-resource views, including the masthead
# and controls, from the active home theme before applying show views.
module Hyrax
  module WorksHomeThemeDecorator
    extend ActiveSupport::Concern

    include Hyku::HomePageThemesBehavior

    prepended do
      skip_around_action :inject_theme_views, raise: false
      around_action :inject_theme_views, only: :show
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
  controller.prepend(Hyrax::WorksHomeThemeDecorator) unless controller < Hyrax::WorksHomeThemeDecorator
end
