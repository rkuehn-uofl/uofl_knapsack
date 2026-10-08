# frozen_string_literal: true

# UOFL OVERRIDE NEW FILE: backs the "Download image" link in
# app/views/hyrax/file_sets/media_display/_image.html.erb.
#
# Public image downloads are limited to the same low-res size the Universal
# Viewer's download dialog offers (uofl_uv_config.json:
# downloadDialogue.options.confinedImageSize, with the high-res option
# disabled). Instead of hyrax.download_path (the full-size original), the link
# points at the IIIF image server with a "!600,600" size: scaled so the longest
# side is at most 600px, aspect ratio kept, never upscaled past the original.
module UoflImageDownloadHelper
  UOFL_IMAGE_DOWNLOAD_MAX_SIZE = 600

  # @param file_set [Hyrax::FileSetPresenter]
  # @return [String, nil] nil when no IIIF image URL can be built, so the view
  #   can fall back to Hyrax's normal download link
  def uofl_small_image_download_url(file_set)
    return unless Hyrax.config.iiif_image_server?

    # DisplaysImage#latest_file_id is private in Hyrax 5.2.0 but is exactly
    # what Hyrax itself feeds the IIIF URL builder for manifests/thumbnails.
    file_id = file_set.send(:latest_file_id)
    return if file_id.blank?

    size = "!#{UOFL_IMAGE_DOWNLOAD_MAX_SIZE},#{UOFL_IMAGE_DOWNLOAD_MAX_SIZE}"
    Hyrax.config.iiif_image_url_builder.call(file_id, request.base_url, size, 'jpg')
  end

  # Suggested filename for the browser's save dialog, e.g. "1981_008_004_pt.jpg".
  def uofl_small_image_download_filename(file_set)
    "#{File.basename(file_set.to_s.presence || file_set.id, '.*')}.jpg"
  end
end
