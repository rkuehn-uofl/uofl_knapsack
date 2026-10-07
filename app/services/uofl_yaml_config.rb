# frozen_string_literal: true

# UOFL OVERRIDE: UofL Theme
#
# Shared, failure-tolerant loader for the curator-edited uofl_*.yml config
# files (UoflHeroImages, UoflFeaturedCarouselThemes, UoflPopularCollections).
# Those files are re-read on every request and hand-edited, so a missing
# file or a YAML typo mustn't take pages down - the masthead's Popular
# Collections list renders on every page. Instead, `.load` logs the problem
# and returns an empty config, so each caller falls back to its own default
# (hardcoded hero image, hidden carousel, alphabetical collections). `.error`
# returns the same problem as a message for the signed-in preview pages to
# show, since otherwise a broken file is only visible in the log.
module UoflYamlConfig
  class InvalidConfig < StandardError; end

  ERRORS = [SystemCallError, Psych::Exception, InvalidConfig].freeze

  def self.load(path, permitted_classes: [])
    parse(path, permitted_classes)
  rescue *ERRORS => e
    Rails.logger.error("UofL config: couldn't read #{path} (#{e.message}), using defaults instead")
    {}
  end

  # nil when the file loads fine, otherwise a message saying what's wrong.
  def self.error(path, permitted_classes: [])
    parse(path, permitted_classes)
    nil
  rescue *ERRORS => e
    e.message
  end

  def self.parse(path, permitted_classes)
    config = YAML.safe_load_file(path, permitted_classes: permitted_classes, symbolize_names: true) || {}
    raise InvalidConfig, "#{path}: expected key/value settings at the top level, not a plain list or value" unless config.is_a?(Hash)

    config
  end
  private_class_method :parse
end
