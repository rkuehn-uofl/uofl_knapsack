# frozen_string_literal: true

# UOFL OVERRIDE: Add Turnstile verification route for public-page protection.
HykuKnapsack::Engine.routes.draw do
  post 'turnstile/verify', to: '/turnstile#verify', as: :turnstile_verify

  # UOFL OVERRIDE: Signed-in-only preview of every configured featured
  # carousel group - see UoflFeaturedCarouselPreviewsController.
  get 'uofl/featured_carousels/preview', to: '/uofl_featured_carousel_previews#show', as: :uofl_featured_carousel_preview

  # UOFL OVERRIDE: Signed-in-only preview of the homepage hero rotation and
  # any configured overrides - see UoflHeroImagesPreviewsController.
  get 'uofl/hero_images/preview', to: '/uofl_hero_images_previews#show', as: :uofl_hero_images_preview

  # UOFL OVERRIDE: Entry point for UofL's copy of the Universal Viewer iframe
  # - see Hyrax::IiifHelperDecorator#universal_viewer_base_url and
  # app/views/uofl_uv_viewer/show.html.erb.
  get 'uofl_uv/uv.html', to: '/uofl_uv_viewer#show', as: :uofl_uv_viewer
end
