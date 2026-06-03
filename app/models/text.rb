# frozen_string_literal: true

# UOFL OVERRIDE NEW FILE: Add a Text work type for UofL Digital Collections deposits.
# Generated via
#  `rails generate hyrax:work_resource Text`
class Text < Hyrax::Work
  if Hyrax.config.work_include_metadata?
    include Hyrax::Schema(:core_metadata) unless Hyrax.config.work_default_metadata?
    include Hyrax::Schema(:basic_metadata)
    include Hyrax::Schema(:text)
    include Hyrax::Schema(:with_pdf_viewer)
    include Hyrax::Schema(:with_video_embed)
  end

  # In flexible mode, this model must opt in so the active M3 profile
  # defines runtime attributes like depositor/admin_set_id/publisher.
  acts_as_flexible_resource if Hyrax.config.flexible?

  include Hyrax::ArResource
  include Hyrax::NestedWorks

  # prepend OrderAlready.for(:creator)
end
