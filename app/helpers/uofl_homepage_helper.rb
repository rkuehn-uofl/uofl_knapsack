# UOFL OVERRIDE: UofL Theme
#
# Shared helpers for the redesigned homepage, all_collections, and shared
# masthead: a live item count for a collection (Hyrax::CollectionPresenter
# #total_items isn't available on the plain SolrDocument/WorkShowPresenter
# objects these pages work with, so we run the same Solr query directly),
# and formatting for the counts shown in the UI.
module UoflHomepageHelper
  # The masthead renders on every uofl-themed page (not just the homepage),
  # so unlike @collections it can't rely on Hyrax::HomepageController's
  # load_shared_info having run. This mirrors that same controller's private
  # `collections` query so the nav's "Popular Collections" list is real.
  def uofl_top_collections(rows: 4)
    Hyrax::CollectionsService.new(controller).search_results do |builder|
      builder.rows(rows)
      builder.merge(sort: 'title_ssi asc')
    end
  rescue Blacklight::Exceptions::ECONNREFUSED, Blacklight::Exceptions::InvalidRequest
    []
  end

  def uofl_collection_item_count(collection_id)
    Hyrax::SolrQueryService.new
                            .with_field_pairs(field_pairs: { 'member_of_collection_ids_ssim' => collection_id.to_s })
                            .count
  end

  def uofl_item_count_label(count)
    "#{number_with_delimiter(count)} #{'item'.pluralize(count)}"
  end

  # Normalized slide/card data for the homepage carousel and "Browse
  # Collections" grid: real collection data (title, description, link, live
  # item count) from the admin-curated Featured Collections list, falling
  # back to the top collections by title if none are featured yet. Images
  # are hand-picked (see UoflCuratedImages), not pulled from the collection.
  def uofl_homepage_collection_slides(limit: 4)
    items = @featured_collection_list&.featured_collections
    items = items.presence || uofl_top_collections(rows: limit)

    items.first(limit).each_with_index.map do |item, index|
      object = item.respond_to?(:presenter) ? item.presenter : item
      title = object.respond_to?(:title_or_label) ? object.title_or_label : Array(object.title).first

      image = UoflCuratedImages.for_carousel_slide(index)

      {
        id: object.id,
        title: title,
        description: Array(object.description).compact_blank.first,
        url: polymorphic_path([hyrax, object]),
        count: uofl_collection_item_count(object.id),
        image_src: image_path(image[:image]),
        image_alt: image[:alt]
      }
    end
  end
end
