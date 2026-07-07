# frozen_string_literal: true

# UOFL OVERRIDE NEW FILE: Add the Valkyrie form object for the Text work type.
class TextForm < Hyrax::Forms::ResourceForm(Text)
  if Hyrax.config.work_include_metadata?
    include Hyrax::FormFields(:basic_metadata)
    include Hyrax::FormFields(:with_pdf_viewer)
    include Hyrax::FormFields(:with_video_embed)
  end
  check_if_flexible(Text)

  include VideoEmbedBehavior::Validation
end
