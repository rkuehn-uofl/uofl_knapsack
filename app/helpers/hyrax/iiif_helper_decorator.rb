# frozen_string_literal: true

# UOFL OVERRIDE: Points the Universal Viewer iframe at UofL's own uv.html
# (app/views/uofl_uv_viewer/show.html.erb - CSS-hides the download/share
# footer buttons that uv-config.json can't reach) and its ?config= param at
# UofL's own uv-config.json (served through the asset pipeline - see
# config/initializers/assets.rb) instead of hyrax-webapp's
# public/uv/{uv.html,uv-config.json}.
#
# Overriding universal_viewer_base_url directly (not iiif_viewer_base_url)
# because the actually-rendered _universal_viewer.html.erb partial comes from
# the iiif_print gem (app/views/hyrax/base/iiif_viewers/_universal_viewer.
# html.erb there wins view-path resolution over Hyrax's own), and
# IiifPrint::IiifHelperDecorator#universal_viewer_base_url builds its URL
# straight from IiifPrint.config.uv_base_path - it never calls
# iiif_viewer_base_url, so overriding that method has no effect here.
module Hyrax
  module IiifHelperDecorator
    def universal_viewer_base_url
      "#{request&.base_url}/uofl_uv/uv.html"
    end

    def universal_viewer_config_url
      "#{request&.base_url}#{asset_path('uofl_uv_config.json')}"
    end
  end
end

Hyrax::IiifHelper.prepend(Hyrax::IiifHelperDecorator)
