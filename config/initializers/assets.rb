# frozen_string_literal: true

# UOFL OVERRIDE: Hyrax's own precompile list (hyrax/engine.rb) only covers
# %w[*.png *.jpg *.ico *.gif *.svg] - .webp isn't included, so any .webp
# asset raises Sprockets::Rails::Helper::AssetNotPrecompiledError.
Rails.application.config.assets.precompile += %w[*.webp]
