# frozen_string_literal: true

# UOFL OVERRIDE NEW FILE: Add the Hyrax controller for the Text work type.
# Generated via
#  `rails generate hyrax:work_resource Text`
module Hyrax
  # Generated controller for Text
  class TextsController < ApplicationController
    # Adds Hyrax behaviors to the controller.
    include Hyrax::WorksControllerBehavior
    include Hyku::WorksControllerBehavior
    include Hyrax::BreadcrumbsForWorks
    self.curation_concern_type = ::Text

    # Use a Valkyrie aware form service to generate Valkyrie::ChangeSet style
    # forms.
    self.work_form_service = Hyrax::FormFactory.new
  end
end
