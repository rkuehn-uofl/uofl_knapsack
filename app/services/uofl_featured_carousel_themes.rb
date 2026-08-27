# frozen_string_literal: true

# UOFL OVERRIDE: UofL Theme
#
# Loads the human-curated "Featured Theme" carousel groups for the homepage
# from config/uofl_featured_carousel_themes.yml. Each group is one theme -
# a title/description/search_path shown once - plus a list of pictures that
# cycle through it. Normally the group named by the file's `active_group`
# key is shown on the homepage, so a curator can swap the whole carousel by
# changing that one value - but a group carrying its own `start_date`/
# `end_date` automatically takes over for that window instead, letting a
# curator schedule a seasonal carousel ahead of time without touching
# `active_group` (see the config file for the precedence rules). All
# groups (not just the effective one) are available via
# `.for_group`/`.group_names`, which power the signed-in-only carousel
# preview page (UoflFeaturedCarouselPreviewsController) that lets a curator
# check a new group before making it active. See the config file for the
# entry format and instructions for adding a group; see
# UoflHomepageHelper#uofl_featured_carousel_slides for how a group's
# pictures are resolved into carousel slide data.
class UoflFeaturedCarouselThemes
  CONFIG_PATH = HykuKnapsack::Engine.root.join('config', 'uofl_featured_carousel_themes.yml')

  def self.all
    for_group(active_group_name)
  end

  # The group actually shown on the homepage today: whichever group is
  # scheduled for today (see .scheduled_group_name), otherwise the
  # configured `active_group`.
  def self.active_group_name
    scheduled_group_name || active_group
  end

  def self.active_group
    config[:active_group]
  end

  def self.group_names
    groups.keys
  end

  def self.for_group(name)
    groups[name&.to_sym]
  end

  def self.groups
    config[:groups] || {}
  end

  # Whether a group carries a `start_date`/`end_date` at all - a plain
  # group (neither set) is only ever shown via `active_group`, never
  # automatically scheduled.
  def self.scheduled?(group)
    group[:start_date].present? || group[:end_date].present?
  end

  def self.config
    YAML.safe_load_file(CONFIG_PATH, permitted_classes: [Date], symbolize_names: true) || {}
  end

  # The name of whichever scheduled group's window covers today, if any -
  # takes precedence over `active_group`. If more than one scheduled
  # group's window covers today, the first one listed under `groups:` wins
  # and a warning is logged - so avoid giving two groups overlapping
  # windows.
  def self.scheduled_group_name
    today = Time.zone.today
    matches = groups.select { |_name, group| scheduled?(group) && group_active_on?(group, today) }

    if matches.size > 1
      Rails.logger.warn(
        "UofL featured carousel: #{matches.size} groups are scheduled for today (#{today}) " \
        "(#{matches.keys.join(', ')}); using the first and ignoring the rest. " \
        "Overlapping scheduled windows between groups should be avoided."
      )
    end

    matches.keys.first
  end
  private_class_method :scheduled_group_name

  def self.group_active_on?(group, date)
    start_date = parse_date(group[:start_date])
    end_date = parse_date(group[:end_date])

    (start_date.nil? || date >= start_date) && (end_date.nil? || date <= end_date)
  end
  private_class_method :group_active_on?

  def self.parse_date(value)
    return nil if value.blank?
    return value if value.is_a?(Date)

    Date.parse(value.to_s)
  end
  private_class_method :parse_date
end
