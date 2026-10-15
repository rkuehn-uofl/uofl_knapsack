# frozen_string_literal: true

RSpec.describe Hyrax::RedirectToDisplayUrlQueryDecorator do
  it 'reaches the work and collection show controllers' do
    expect([Hyrax::ImagesController, Hyrax::TextsController, Hyrax::CollectionsController])
      .to all(be < described_class)
  end

  describe '#with_locale' do
    let(:controller) { Hyrax::CollectionsController.new }
    let(:request) { ActionDispatch::TestRequest.create('QUERY_STRING' => query) }

    before do
      allow(controller).to receive(:request).and_return(request)
      allow(controller).to receive(:params).and_return(ActionController::Parameters.new(request.query_parameters))
    end

    def redirect_path(path = '/ulpa_1980_020')
      controller.send(:with_locale, path)
    end

    context 'with sort and paging params' do
      let(:query) { 'locale=en&page=2&per_page=50&sort=title_ssi+asc' }

      it 'keeps every param, not just locale' do
        expect(redirect_path).to eq('/ulpa_1980_020?locale=en&page=2&per_page=50&sort=title_ssi+asc')
      end

      it 'appends to a path that already has a query string' do
        expect(redirect_path('/ulpa_1980_020?a=1')).to start_with('/ulpa_1980_020?a=1&locale=en&')
      end
    end

    context 'with a value that tries to add its own params' do
      let(:query) { 'locale=en%26admin%3Dtrue' }

      it 'keeps it encoded as one value' do
        expect(redirect_path).to eq('/ulpa_1980_020?locale=en%26admin%3Dtrue')
      end
    end

    context 'with no query string' do
      let(:query) { '' }

      it 'returns the bare path' do
        expect(redirect_path).to eq('/ulpa_1980_020')
      end
    end
  end
end
