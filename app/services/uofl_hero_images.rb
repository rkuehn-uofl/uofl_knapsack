# frozen_string_literal: true

# UOFL OVERRIDE: UofL Theme
#
# Resolves which single image to show in the homepage hero banner, from
# config/uofl_hero_images.yml: a date-scoped `overrides` entry if one is
# active today, otherwise the configured rotation through `images` (weekly,
# or random per visit).
# See that file for the full format and how curators are meant to edit it;
# see UoflHomepageHelper#uofl_hero_image for how the picked entry is turned
# into rendered image/link data (including resolving its optional
# `work_id`).
class UoflHeroImages
  CONFIG_PATH = HykuKnapsack::Engine.root.join('config', 'uofl_hero_images.yml')

  # Hardcoded safety net for when `images` in the config ends up empty (or
  # the file itself is missing/unparseable) - the hero should never render
  # broken just because the config is misconfigured. Matches the image the
  # hero previously had hardcoded, before it became config-driven.
  FALLBACK_IMAGE = 'themes/uofl/homepage/hero/ULPA_R_18596_00_1200x800_80.webp'
  FALLBACK_ALT = 'Night photos of long distance operators'

  # The rotation advances once per this many days, counted from a fixed
  # epoch rather than the calendar week number, so it never skips or
  # repeats a beat crossing a year boundary.
  ROTATION_DAYS = 7
  ROTATION_EPOCH = Date.new(2024, 1, 1)

  ROTATION_MODES = %w[weekly random].freeze
  DEFAULT_ROTATION_MODE = 'weekly'

  # In `random` mode, how long a visitor keeps the same picture after they
  # last saw the hero before the next homepage view counts as a new visit
  # and gets a different one. 0 means a new picture on every page load.
  DEFAULT_VISIT_TIMEOUT_MINUTES = 30

  # `remembered_image` is the `image` path of whatever picture this same
  # visitor was already shown, if any, and `remembered_at` is when (epoch
  # seconds) they last saw it (in `random` mode, the caller is expected to
  # have read both back out of its own session storage - see
  # UoflHomepageHelper#uofl_hero_image). Both are ignored entirely in
  # `weekly` mode, so callers that don't pass them (or that don't have a
  # session, like a Rails console) still get the same deterministic weekly
  # pick as always.
  def self.current(remembered_image: nil, remembered_at: nil)
    active_override || pick_image(remembered_image, remembered_at) || fallback_image
  end

  def self.rotation_mode
    mode = config[:rotation_mode].to_s
    ROTATION_MODES.include?(mode) ? mode : DEFAULT_ROTATION_MODE
  end

  # A missing, non-integer, or negative value falls back to the default
  # rather than breaking the hero.
  def self.visit_timeout_minutes
    minutes = Integer(config[:visit_timeout_minutes], exception: false)
    minutes.nil? || minutes.negative? ? DEFAULT_VISIT_TIMEOUT_MINUTES : minutes
  end

  def self.images
    Array(config[:images])
  end

  def self.overrides
    Array(config[:overrides])
  end

  def self.active_override
    today = Time.zone.today
    matches = overrides.select { |override| override_active_on?(override, today) }
    dated, undated = matches.partition { |override| override[:start_date].present? || override[:end_date].present? }

    # A dated override always wins over an undated one, regardless of list
    # order - this is what lets a curator keep a standing, undated override
    # in place and temporarily supersede it with a dated one (e.g. a
    # holiday image), then have the standing override resume automatically
    # once the dated one's window ends.
    using_dated_tier = dated.present?
    tier = using_dated_tier ? dated : undated

    if tier.size > 1
      Rails.logger.warn(
        "UofL hero image: #{tier.size} overrides are active today (#{today}) at the same precedence " \
        "tier (#{using_dated_tier ? 'dated' : 'undated'}); using the first and ignoring the rest. " \
        "Overlapping overrides at the same tier should not share a date range."
      )
    end

    tier.first
  end

  def self.pick_image(remembered_image, remembered_at)
    return nil if images.empty?

    rotation_mode == 'random' ? random_image(remembered_image, remembered_at) : rotated_image
  end

  def self.rotated_image
    weeks_elapsed = (Time.zone.today - ROTATION_EPOCH).to_i / ROTATION_DAYS
    images[weeks_elapsed % images.size]
  end

  # Sticks with `remembered_image` while the visitor is still within the
  # same visit (so refreshing/navigating back to the homepage doesn't
  # change the hero mid-visit) and it's still a valid picture; otherwise
  # picks a fresh random one for the caller to remember from here on,
  # never the one they just saw (when there's more than one to choose
  # from). Matching on `image` (always present) rather than `work_id`
  # (optional) or list position (would silently pick a different photo if
  # a curator reorders the list).
  def self.random_image(remembered_image, remembered_at)
    remembered = images.find { |image| image[:image] == remembered_image }
    return remembered if remembered && same_visit?(remembered_at)

    candidates = images.reject { |image| image[:image] == remembered_image }
    (candidates.presence || images).sample
  end

  # A missing timestamp (e.g. a session from before visit tracking existed)
  # counts as a new visit.
  def self.same_visit?(remembered_at)
    return false if remembered_at.blank?

    Time.current.to_i - remembered_at.to_i < visit_timeout_minutes * 60
  end

  def self.fallback_image
    { image: FALLBACK_IMAGE, image_alt: FALLBACK_ALT, work_id: nil }
  end

  # A missing or malformed file loads as an empty config (see UoflYamlConfig).
  def self.config
    UoflYamlConfig.load(CONFIG_PATH, permitted_classes: [Date])
  end

  # nil if the config file loads fine, otherwise what's wrong with it - for
  # the preview page.
  def self.config_error
    UoflYamlConfig.error(CONFIG_PATH, permitted_classes: [Date])
  end

  def self.override_active_on?(override, date)
    start_date = parse_date(override[:start_date])
    end_date = parse_date(override[:end_date])

    (start_date.nil? || date >= start_date) && (end_date.nil? || date <= end_date)
  end
  private_class_method :override_active_on?

  def self.parse_date(value)
    return nil if value.blank?
    return value if value.is_a?(Date)

    Date.parse(value.to_s)
  end
end
