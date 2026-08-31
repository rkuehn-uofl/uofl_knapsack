# frozen_string_literal: true

# UOFL OVERRIDE: UofL Theme
#
# Signed-in-only page that renders every configured "Featured Theme"
# carousel group (see config/uofl_featured_carousel_themes.yml) side by
# side, along with each scheduled group's configured window (start/end
# date), so a curator can check how a new group looks - or
# check a new schedule before its date arrives - before it goes live on
# the homepage. Mirrors UoflHeroImagesPreviewsController's approach for
# the hero banner. This whole feature only makes sense for the uofl theme
# (it previews uofl's featured-carousel config), so its view lives under
# app/views/themes/uofl like every other uofl-specific view in this app,
# rather than in the generic views root.
class UoflFeaturedCarouselPreviewsController < ApplicationController
  # Same concern Hyrax::HomepageController uses for all_collections/show -
  # prepends app/views/themes/uofl to the view_paths for this request, which
  # is what swaps in the real UofL masthead (see app/views/themes/uofl/
  # _masthead.html.erb) instead of the generic one.
  include Hyku::HomePageThemesBehavior

  # Same layout Hyrax::HomepageController uses, so its non-hero branch (any
  # action other than `index` - see app/views/themes/uofl/layouts/
  # homepage.html.erb) renders this page with the same header all_collections
  # gets, action name `show` avoids that branch's `index` special-case.
  layout 'homepage'

  before_action :ensure_admin!
  def ensure_admin!
    authorize! :read, :admin_dashboard
  end

  def show
    @group_names = UoflFeaturedCarouselThemes.group_names
    @active_group = UoflFeaturedCarouselThemes.active_group
    @active_group_name = UoflFeaturedCarouselThemes.active_group_name
    @group_schedules = @group_names.index_with do |name|
      group = UoflFeaturedCarouselThemes.for_group(name)
      next nil unless UoflFeaturedCarouselThemes.scheduled?(group)

      { start_date: group[:start_date], end_date: group[:end_date] }
    end
  end
end
