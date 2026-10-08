# frozen_string_literal: true

# UOFL OVERRIDE: Disable Blacklight bookmarks entirely. Hyku already hides the
# bookmark UI (CatalogController#render_bookmarks_control? is false), but the
# /bookmarks routes stay reachable by anonymous guest users. Every action 404s.
module BookmarksControllerDecorator
  extend ActiveSupport::Concern

  included do
    prepend_before_action :uofl_disable_bookmarks
  end

  private

  def uofl_disable_bookmarks
    raise ActionController::RoutingError, 'Not Found'
  end
end

BookmarksController.include(BookmarksControllerDecorator) unless BookmarksController < BookmarksControllerDecorator
