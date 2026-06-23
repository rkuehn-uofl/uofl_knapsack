# frozen_string_literal: true

RSpec.describe 'public theme controller wiring' do
  it 'loads the active home theme for catalog pages' do
    expect(CatalogController).to be < Hyku::HomePageThemesBehavior
  end

  it 'loads the active home theme for work pages' do
    controllers = [
      Hyrax::EtdsController,
      Hyrax::GenericWorksController,
      Hyrax::ImagesController,
      Hyrax::OersController,
      Hyrax::TextsController
    ]

    expect(controllers).to all(be < Hyrax::WorksHomeThemeDecorator)
  end
end
