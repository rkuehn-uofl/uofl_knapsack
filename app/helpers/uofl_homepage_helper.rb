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
  # item count, and branding thumbnail image) from the admin-curated
  # Featured Collections list, falling back to the top collections by title
  # if none are featured yet. Images come from each collection's branding
  # thumbnail (same source as `thumbnail_url`/`render_thumbnail_tag`
  # elsewhere in the app); Hyrax's own ThumbnailPathService already falls
  # back to its default.png when a collection has no thumbnail set, so
  # thumbnail_url never returns blank here.
  def uofl_homepage_collection_slides(limit: 4)
    items = @featured_collection_list&.featured_collections
    items = items.presence || uofl_top_collections(rows: limit)

    items.first(limit).map do |item|
      object = item.respond_to?(:presenter) ? item.presenter : item
      solr_document = object.respond_to?(:solr_document) ? object.solr_document : object
      title = object.respond_to?(:title_or_label) ? object.title_or_label : Array(object.title).first

      {
        id: object.id,
        title: title,
        description: Array(object.description).compact_blank.first,
        url: polymorphic_path([hyrax, object]),
        count: uofl_collection_item_count(object.id),
        image_src: thumbnail_url(object),
        image_alt: thumbnail_alt_text_for(solr_document, block_name: 'default_collection_image_text')
      }
    end
  end

  # Slide data for the homepage's curated "Featured Theme" carousel (see
  # UoflFeaturedCarouselThemes for the config format). A group's
  # title/description/search link are hand-written by a curator and shared
  # by every slide; only each picture's item number and the link to its own
  # work record are looked up live (from that picture's `work_id`, which is
  # the item's human-readable identifier, e.g. "ULPA 1981_008_004" - not a
  # system-generated id), so those two details can't drift out of sync with
  # the actual record. A picture is silently skipped, with a logged
  # warning, if its work_id no longer resolves to a real work. `notes` is
  # ignored here - it's a plain YAML field for curators, not read by any
  # code.
  #
  # A picture's `image`/`image_alt` are optional: without them the work's
  # own thumbnail and title stand in, so a picture is never missing an
  # image just because no one has hand-cropped a hero image for it yet.
  #
  # `group:` resolves a specific named group instead of the active one -
  # used by the carousel preview page to render every configured group.
  def uofl_featured_carousel_slides(limit: 4, group: nil)
    theme = group ? UoflFeaturedCarouselThemes.for_group(group) : UoflFeaturedCarouselThemes.all
    return [] unless theme

    Array(theme[:pictures]).first(limit).filter_map do |picture|
      solr_document = uofl_find_by_item_number(picture[:work_id])

      unless solr_document
        Rails.logger.warn("UofL featured carousel: item number #{picture[:work_id]} not found, skipping picture in theme '#{theme[:title]}'")
        next
      end

      item_number = Array(solr_document[:source_identifier_tesim]).first
      work_title = Array(solr_document[:title_tesim]).first

      {
        title: theme[:title],
        description: theme[:description],
        search_url: theme[:search_path],
        item_number: item_number,
        item_url: polymorphic_path([main_app, solr_document]),
        image_src: picture[:image].present? ? image_path(picture[:image]) : thumbnail_url(solr_document),
        image_alt: picture[:image_alt].presence || "#{work_title} (item #{item_number})"
      }
    end
  end

  # Resolved image/link data for the homepage hero banner (see
  # app/views/themes/uofl/hyrax/homepage/_hero.html.erb for the markup and
  # UoflHeroImages for how the picture itself is picked - an active
  # config/uofl_hero_images.yml override, or the configured rotation:
  # deterministic weekly, or random per session). In `random` mode this
  # reads/writes session[:uofl_hero_image] so the same visitor
  # keeps seeing the same picture for the rest of their session instead of
  # it changing on every request; an active override always wins and is
  # never written to the session, so a visitor's earlier random pick (if
  # any) resumes once the override's window ends. The hero's lower-right
  # item-number button is optional: a picture only gets one if it has a
  # `work_id` AND that work_id resolves to a real work; otherwise
  # item_number/item_url come back nil and the view hides the button
  # rather than linking to nothing.
  def uofl_hero_image
    picture = UoflHeroImages.current(remembered_image: session[:uofl_hero_image])

    if UoflHeroImages.rotation_mode == 'random' && UoflHeroImages.active_override.blank?
      session[:uofl_hero_image] = picture[:image]
    end

    solr_document = picture[:work_id].present? ? uofl_find_by_item_number(picture[:work_id]) : nil

    if picture[:work_id].present? && solr_document.nil?
      Rails.logger.warn("UofL hero image: item number #{picture[:work_id]} not found, hiding its item-number button")
    end

    {
      image_src: image_path(picture[:image]),
      image_alt: picture[:image_alt],
      item_number: solr_document && Array(solr_document[:source_identifier_tesim]).first,
      item_url: solr_document && polymorphic_path([main_app, solr_document])
    }
  end

  # Looks up a work by its human-readable item number (`source_identifier`,
  # e.g. "ULPA 1981_008_004") rather than its system id, so curators can
  # write `work_id` values in config/uofl_featured_carousel_themes.yml that
  # they can find and verify on the item itself instead of having to copy a
  # UUID out of a URL. The underlying Solr field is analyzed text, but an
  # exact `{!field}` query still matches the identifier as a whole
  # (case-insensitively) rather than any of its words individually.
  def uofl_find_by_item_number(item_number)
    Hyrax::SolrQueryService.new
                            .with_field_pairs(field_pairs: { 'source_identifier_tesim' => item_number.to_s })
                            .solr_documents
                            .first
  end
end
