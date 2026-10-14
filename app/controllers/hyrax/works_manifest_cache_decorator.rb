# frozen_string_literal: true

# UOFL OVERRIDE: Fix a 500 (AbstractController::DoubleRenderError) on IIIF
# manifest revalidation requests, which the Universal Viewer reports as
# "Unable to load manifest".
#
# Hyku::WorksControllerBehavior#manifest calls `fresh_when` and then `super`
# unconditionally. When the browser's cached copy has expired (max-age=3600)
# and it revalidates with a still-matching If-None-Match ETag, `fresh_when`
# sends a 304 and `super` then renders the JSON as well.
#
# Hyku defines #manifest inside its `included do` block, so the method lives on
# each work controller class itself and can't be fixed by prepending to the
# Hyku module. This is prepended to each controller instead, and calls Hyrax's
# original #manifest directly, skipping Hyku's broken wrapper.
module Hyrax
  module WorksManifestCacheDecorator
    def manifest
      return unless stale?(iiif_manifest_presenter)
      expires_in 1.hour, public: true
      hyrax_manifest
    end

    private

    def hyrax_manifest
      Hyrax::WorksControllerBehavior.instance_method(:manifest).bind_call(self)
    end
  end
end

[
  Hyrax::EtdsController,
  Hyrax::GenericWorksController,
  Hyrax::ImagesController,
  Hyrax::OersController,
  Hyrax::TextsController
].each do |controller|
  controller.prepend(Hyrax::WorksManifestCacheDecorator) unless controller < Hyrax::WorksManifestCacheDecorator
end
