# frozen_string_literal: true

# UOFL OVERRIDE NEW FILE: Configure Cloudflare Turnstile from environment variables.
Rails.application.config.x.turnstile = ActiveSupport::OrderedOptions.new
Rails.application.config.x.turnstile.enabled = ActiveModel::Type::Boolean.new.cast(ENV.fetch('TURNSTILE_ENABLED', false))
Rails.application.config.x.turnstile.site_key = ENV['TURNSTILE_SITE_KEY']
Rails.application.config.x.turnstile.secret_key = ENV['TURNSTILE_SECRET_KEY']
Rails.application.config.x.turnstile.bypass =
  Rails.env.development? &&
  ActiveModel::Type::Boolean.new.cast(ENV.fetch('TURNSTILE_BYPASS', false))
