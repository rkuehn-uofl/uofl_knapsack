# frozen_string_literal: true

# UOFL OVERRIDE NEW FILE: Serves UofL's own copy of the Universal Viewer's
# iframe entry point (hyrax-webapp's public/uv/uv.html, which we don't edit -
# see app/views/uofl_uv_viewer/show.html.erb for why) at the path
# Hyrax::IiifHelperDecorator#universal_viewer_base_url points at.
class UoflUvViewerController < ApplicationController
  layout false

  def show; end
end
