# frozen_string_literal: true

# UOFL OVERRIDE NEW FILE: Add Solr indexing behavior for the Text work type.
class TextIndexer < Hyrax::ValkyrieWorkIndexer
  if Hyrax.config.work_include_metadata?
    include Hyrax::Indexer(:core_metadata)
    include Hyrax::Indexer(:basic_metadata)
    include Hyrax::Indexer(:with_pdf_viewer)
    include Hyrax::Indexer(:with_video_embed)
  end
  check_if_flexible(Text)

  include HykuIndexing
end
