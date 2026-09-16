# frozen_string_literal: true

# UOFL OVERRIDE: index a single-valued source_identifier_ssi field so the
# public catalog's "Item Number" sort option (CatalogControllerDecorator
# #configure_uofl_sort_fields) has something sortable to sort on.
#
# The M3 profile's source_identifier property is indexed as source_identifier_sim
# / source_identifier_tesim -- both declared multiValued="true" in
# hyrax-webapp/solr/conf/schema.xml, which Solr refuses to sort on. Rather than
# relying on the flexible-schema (M3) profile's own "indexing:" list for a new
# *_ssi entry -- which in testing did not take effect for already-booted work
# classes even across container restarts, seemingly because each work class's
# flexible index rules are memoized once at first autoload -- this reads the
# resource's source_identifier attribute directly and writes the sortable
# field itself, sidestepping that caching entirely.
#
# Prepended onto the common base class so it applies to every resource type
# that has a source_identifier (currently CollectionResource, ImageResource,
# Text per metadata-profile-main.yml's available_on list) without needing to
# touch each work type's own indexer (several of which live in the read-only
# hyrax-webapp submodule).
module ResourceIndexerDecorator
  def to_solr
    super.tap do |index_document|
      next unless resource.respond_to?(:source_identifier)

      value = Array(resource.source_identifier).compact_blank.first
      index_document['source_identifier_ssi'] = value if value.present?
    end
  end
end

Hyrax::Indexers::ResourceIndexer.prepend(ResourceIndexerDecorator)
