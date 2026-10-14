# frozen_string_literal: true

RSpec.describe Hyrax::WorksManifestCacheDecorator do
  let(:work_controllers) do
    [
      Hyrax::EtdsController,
      Hyrax::GenericWorksController,
      Hyrax::ImagesController,
      Hyrax::OersController,
      Hyrax::TextsController
    ]
  end

  it 'overrides Hyku #manifest on every work controller' do
    expect(work_controllers).to all(be < described_class)
    expect(work_controllers.map { |c| c.instance_method(:manifest).owner }).to all(eq(described_class))
  end

  describe '#manifest' do
    let(:controller) { Hyrax::ImagesController.new }
    let(:presenter) { instance_double(Hyrax::IiifManifestPresenter) }

    before do
      allow(controller).to receive(:iiif_manifest_presenter).and_return(presenter)
      allow(controller).to receive(:expires_in)
      allow(controller).to receive(:hyrax_manifest)
    end

    context 'when the browser revalidates with a matching ETag' do
      before { allow(controller).to receive(:stale?).with(presenter).and_return(false) }

      it 'stops after the 304 instead of rendering the manifest too' do
        controller.manifest

        expect(controller).not_to have_received(:hyrax_manifest)
        expect(controller).not_to have_received(:expires_in)
      end
    end

    context 'when the browser has no current cached copy' do
      before { allow(controller).to receive(:stale?).with(presenter).and_return(true) }

      it 'sets the cache lifetime and renders the Hyrax manifest' do
        controller.manifest

        expect(controller).to have_received(:expires_in).with(1.hour, public: true)
        expect(controller).to have_received(:hyrax_manifest)
      end
    end
  end
end
