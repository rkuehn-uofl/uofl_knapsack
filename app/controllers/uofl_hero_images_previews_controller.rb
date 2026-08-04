# frozen_string_literal: true

# UOFL OVERRIDE: UofL Theme
#
# Signed-in-only page showing the full configured homepage hero rotation
# and every override (see config/uofl_hero_images.yml), with each
# override's resolved status (active today / upcoming / expired), so a
# curator can check a new rotation image or a pinned override before its
# date arrives instead of waiting to see it go live. Mirrors
# UoflFeaturedCarouselPreviewsController's approach for the featured
# carousel.
class UoflHeroImagesPreviewsController < ApplicationController
  # Same concern Hyrax::HomepageController uses for all_collections/show -
  # prepends app/views/themes/uofl to the view_paths for this request, which
  # is what swaps in the real UofL masthead (see app/views/themes/uofl/
  # _masthead.html.erb) instead of the generic one.
  include Hyku::HomePageThemesBehavior

  # Same layout Hyrax::HomepageController uses, so its non-hero branch (any
  # action other than `index` - see app/views/themes/uofl/layouts/
  # homepage.html.erb) renders this page with the same header all_collections
  # gets; action name `show` avoids that branch's `index` special-case.
  layout 'homepage'

  before_action :authenticate_user!

  def show
    @current_image = UoflHeroImages.current
    @images = UoflHeroImages.images
    @overrides = UoflHeroImages.overrides.map { |override| override.merge(status: override_status(override)) }
  end

  private

  def override_status(override)
    today = Time.zone.today
    start_date = override[:start_date]
    end_date = override[:end_date]

    return 'upcoming' if start_date && today < start_date
    return 'expired' if end_date && today > end_date

    'active'
  end
end
