# frozen_string_literal: true

# UOFL OVERRIDE: Add Turnstile verification route for public-page protection.
HykuKnapsack::Engine.routes.draw do
  post 'turnstile/verify', to: '/turnstile#verify', as: :turnstile_verify

  # UOFL OVERRIDE: Signed-in-only preview of every configured featured
  # carousel group - see UoflFeaturedCarouselPreviewsController.
  get 'uofl/featured_carousels/preview', to: '/uofl_featured_carousel_previews#show', as: :uofl_featured_carousel_preview
end
