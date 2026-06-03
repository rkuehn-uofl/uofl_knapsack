# frozen_string_literal: true

# UOFL OVERRIDE NEW FILE: Add Solr indexing behavior for the Text work type.
# Generated via
#  `rails generate hyrax:work_resource Text`
class TextIndexer < Hyrax::ValkyrieWorkIndexer
  if Hyrax.config.work_include_metadata?
    include Hyrax::Indexer(:core_metadata)
    include Hyrax::Indexer(:basic_metadata)
    include Hyrax::Indexer(:text)
    include Hyrax::Indexer(:with_pdf_viewer)
    include Hyrax::Indexer(:with_video_embed)
  end
  check_if_flexible(Text)

  include HykuIndexing

  # Uncomment this block if you want to add custom indexing behavior:
  #  def to_solr
  #    super.tap do |index_document|
  #      index_document[:my_field_tesim]   = resource.my_field.map(&:to_s)
  #      index_document[:other_field_ssim] = resource.other_field
  #    end
  #  end
end
