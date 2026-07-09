# UOFL OVERRIDE: UofL Theme
#
# Hand-picked images for the homepage hero and featured-collection carousel.
# These are chosen manually (not pulled from whatever thumbnail Solr returns
# for a collection) so editors keep full control over what the public first
# sees. To swap the current batch: replace/add files under
# app/assets/images/themes/uofl/homepage/ and update the lists below. A
# future scheduled job could rotate HERO/CAROUSEL on its own by editing this
# same list on a cadence.
module UoflCuratedImages
  HERO = { image: 'themes/uofl/homepage/placeholder-hero-1.jpg', alt: 'Historic Louisville street scene' }.freeze

  # Matched positionally to the ordered Featured Collections list on the
  # homepage carousel. If there are more featured collections than curated
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
