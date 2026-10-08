# frozen_string_literal: true

# UOFL OVERRIDE: Disable Blacklight's /search_history page (and its clear
# action). Blacklight still records searches in the session; only the page
# that lists them is turned off. Every action 404s.
module SearchHistoryControllerDecorator
  extend ActiveSupport::Concern

  included do
    prepend_before_action :uofl_disable_search_history
  end

  private

  def uofl_disable_search_history
    raise ActionController::RoutingError, 'Not Found'
  end
end

SearchHistoryController.include(SearchHistoryControllerDecorator) unless SearchHistoryController < SearchHistoryControllerDecorator
