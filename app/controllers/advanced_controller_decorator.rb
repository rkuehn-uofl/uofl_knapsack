# frozen_string_literal: true

# UOFL OVERRIDE: Allow AdvancedController to resolve views from the active home theme.
module AdvancedControllerDecorator
  extend ActiveSupport::Concern

  include Hyku::HomePageThemesBehavior
end

AdvancedController.prepend(AdvancedControllerDecorator)
