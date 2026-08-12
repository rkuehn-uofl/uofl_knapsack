# frozen_string_literal: true

# Hyku's Hyrax::ControlledVocabularies.services (hyrax-webapp/config/initializers/
# hyrax_controlled_vocabularies.rb) only maps a handful of M3 controlled_values
# source names to a Ruby service class. A source with no entry here silently
# renders as a plain text field instead of a select, even if the M3 profile
# correctly lists it under controlled_values.sources.
#
# This adds knapsack-specific sources to that map without editing hyrax-webapp.
module Hyrax
  module ControlledVocabulariesDecorator
    def services
      super.merge(
        'format' => 'Hyrax::FormatService',
        'object_type' => 'Hyrax::ObjectTypeService'
      )
    end
  end
end

Hyrax::ControlledVocabularies.singleton_class.prepend(Hyrax::ControlledVocabulariesDecorator)
