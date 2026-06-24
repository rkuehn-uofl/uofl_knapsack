# frozen_string_literal: true

# UOFL OVERRIDE: Resolve shared public-resource views, including the masthead
# and controls, from the active home theme before applying show views.
module Hyrax
  module WorksHomeThemeDecorator
    extend ActiveSupport::Concern

    include Hyku::HomePageThemesBehavior
  end
end

[
  Hyrax::CollectionsController,
  Hyrax::EtdsController,
  Hyrax::GenericWorksController,
  Hyrax::ImagesController,
  Hyrax::OersController,
  Hyrax::TextsController
].each do |controller|
  controller.prepend(Hyrax::WorksHomeThemeDecorator) unless controller < Hyrax::WorksHomeThemeDecorator
end
