# frozen_string_literal: true

# UOFL OVERRIDE: UofL Theme
module Hyrax
  module TitleHelperDecorator
    def uofl_page_title_with_page(base)
      "#{base} - Page #{params[:page].presence || 1}"
    end
  end
end

Hyrax::TitleHelper.prepend(Hyrax::TitleHelperDecorator)
