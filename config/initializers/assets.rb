# frozen_string_literal: true

# UOFL OVERRIDE: Hyrax's own precompile list (hyrax/engine.rb) only covers
# %w[*.png *.jpg *.ico *.gif *.svg] - .webp isn't included, so any .webp
# asset raises Sprockets::Rails::Helper::AssetNotPrecompiledError.
Rails.application.config.assets.precompile += %w[*.webp]

# UOFL OVERRIDE: uofl_uv_config.json isn't referenced from application.js, so
# Sprockets won't compile it unless listed explicitly - see
# Hyrax::IiifHelperDecorator#universal_viewer_config_url.
Rails.application.config.assets.precompile += %w[uofl_uv_config.json]
