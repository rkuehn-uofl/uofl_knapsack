# frozen_string_literal: true

# UOFL OVERRIDE: Supply the direction required by Solr when sorting collections by title,
# and support the all_collections page's user-facing "Sort by" control.
module Hyrax
  module HomepageControllerDecorator
    SORT_OPTIONS = {
      'az' => { label: 'Collection name (A-Z)', solr: 'title_ssi asc' },
      'za' => { label: 'Collection name (Z-A)', solr: 'title_ssi desc' }
    }.freeze

    def all_collections
      @selected_sort = SORT_OPTIONS.key?(params[:collection_sort]) ? params[:collection_sort] : 'az'
      load_shared_info
      @collection_letters = collection_letters(@collections)
      @selected_collection_letter = normalized_collection_letter
      @collection_description_query = params[:collection_description_query].to_s.strip
      @collections = filtered_collections(@collections)
      @collections = resort_collections(@collections)
    end

    private

    def collections(rows: 6)
      Hyrax::CollectionsService.new(self).search_results do |builder|
        builder.rows(rows)
        builder.merge(sort: "title_ssi asc")
      end
    rescue Blacklight::Exceptions::ECONNREFUSED, Blacklight::Exceptions::InvalidRequest
      []
    end

    # The base collections() lookup already asked Solr to sort ascending; when the
    # user picks Z-A we just reverse the already-loaded (and already letter/query
    # filtered) list rather than re-querying Solr for the same rows.
    def resort_collections(collections)
      return collections unless @selected_sort == 'za'
      collections.sort_by { |collection| collection.title_or_label.to_s.downcase }.reverse
    end

    def filtered_collections(collections)
      collections = collections.select { |collection| collection_matches_letter?(collection) } if @selected_collection_letter.present?
      collections = collections.select { |collection| collection_matches_description_query?(collection) } if @collection_description_query.present?
      collections
    end

    def collection_letters(collections)
      collections.filter_map { |collection| collection_title_initial(collection) }.uniq.sort
    end

    def collection_matches_letter?(collection)
      collection_title_initial(collection) == @selected_collection_letter
    end

    def collection_matches_description_query?(collection)
      collection_descriptions(collection).any? { |description| description.downcase.include?(@collection_description_query.downcase) }
    end

    def normalized_collection_letter
      letter = params[:collection_letter].to_s.strip.upcase
      letter.match?(/\A[A-Z]\z/) ? letter : nil
    end

    def collection_title_initial(collection)
      collection.title_or_label.to_s.strip[/[A-Za-z]/]&.upcase
    end

    def collection_descriptions(collection)
      Array(collection.description).compact_blank.map(&:to_s)
    end
  end
end

Hyrax::HomepageController.prepend(Hyrax::HomepageControllerDecorator)
