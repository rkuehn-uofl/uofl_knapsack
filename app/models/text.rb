# frozen_string_literal: true

# UOFL OVERRIDE NEW FILE: Add a Text work type for UofL Digital Collections deposits.
class Text < Hyrax::Work
  if Hyrax.config.work_include_metadata?
    include Hyrax::Schema(:core_metadata) unless Hyrax.config.work_default_metadata?
    include Hyrax::Schema(:basic_metadata)
    include Hyrax::Schema(:with_pdf_viewer)
    include Hyrax::Schema(:with_video_embed)
  end

  acts_as_flexible_resource if Hyrax.config.flexible?

  include Hyrax::ArResource
  include Hyrax::NestedWorks
end
