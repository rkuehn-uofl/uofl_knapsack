# UOFL OVERRIDE: UofL Theme
#
# Hand-picked images for the homepage hero, plus a fallback bank for the
# featured-collection carousel. The carousel itself shows each collection's
# real branding thumbnail (see UoflHomepageHelper#uofl_homepage_collection_slides);
# CAROUSEL here is only used when a featured collection has no branding
# thumbnail set, so editors never see a broken image. To swap the current
# batch: replace/add files under app/assets/images/themes/uofl/homepage/ and
# update the lists below.
module UoflCuratedImages
  HERO = { image: 'themes/uofl/homepage/placeholder-hero-1.jpg', alt: 'Historic Louisville street scene' }.freeze

  # Matched positionally to the ordered Featured Collections list on the
  # homepage carousel, used only as a fallback when a collection has no
  # branding thumbnail. If there are more featured collections than curated
  # images, the list repeats.
  CAROUSEL = [
    { image: 'themes/uofl/homepage/placeholder-photographs.jpg', alt: 'Historic photographic equipment' },
    { image: 'themes/uofl/homepage/placeholder-maps.jpg', alt: 'Historic map detail' },
    { image: 'themes/uofl/homepage/placeholder-newspapers.jpg', alt: 'Stack of historical newspapers' },
    { image: 'themes/uofl/homepage/placeholder-books.jpg', alt: 'Rare books on shelves' }
  ].freeze

  def self.hero
    HERO
  end

  def self.for_carousel_slide(index)
    CAROUSEL[index % CAROUSEL.size]
  end

  # A generic image for chrome that isn't a featured-collection slide (e.g.
  # the Explore mega-menu), reusing one of the curated carousel images.
  def self.generic
    CAROUSEL[1]
  end
end
