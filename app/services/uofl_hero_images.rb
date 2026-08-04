# frozen_string_literal: true

# UOFL OVERRIDE: UofL Theme
#
# Resolves which single image to show in the homepage hero banner, from
# config/uofl_hero_images.yml: a date-scoped `overrides` entry if one is
# active today, otherwise an automatic weekly rotation through `images`.
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
  FALLBACK_IMAGE = 'themes/uofl/homepage/hero/ULUA_2006_003_008_024_1800x1200.jpg'
  FALLBACK_ALT = 'creamery wagons'

  # The rotation advances once per this many days, counted from a fixed
  # epoch rather than the calendar week number, so it never skips or
  # repeats a beat crossing a year boundary.
  ROTATION_DAYS = 7
  ROTATION_EPOCH = Date.new(2024, 1, 1)

  def self.current
    active_override || rotated_image || fallback_image
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

  def self.rotated_image
    return nil if images.empty?

    weeks_elapsed = (Time.zone.today - ROTATION_EPOCH).to_i / ROTATION_DAYS
    images[weeks_elapsed % images.size]
  end

  def self.fallback_image
    { image: FALLBACK_IMAGE, image_alt: FALLBACK_ALT, work_id: nil }
  end

  def self.config
    YAML.safe_load_file(CONFIG_PATH, permitted_classes: [Date], symbolize_names: true) || {}
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
  private_class_method :parse_date
end
