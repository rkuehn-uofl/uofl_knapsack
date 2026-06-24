# frozen_string_literal: true

# UOFL OVERRIDE: Supply the direction required by Solr when sorting collections by title.
module Hyrax
  module HomepageControllerDecorator
    private

    def collections(rows: 6)
      Hyrax::CollectionsService.new(self).search_results do |builder|
        builder.rows(rows)
        builder.merge(sort: "title_ssi asc")
      end
    rescue Blacklight::Exceptions::ECONNREFUSED, Blacklight::Exceptions::InvalidRequest
      []
    end
  end
end

Hyrax::HomepageController.prepend(Hyrax::HomepageControllerDecorator)
