# frozen_string_literal: true

# UOFL OVERRIDE: Keep the whole query string when a work or collection's ID URL
# 301s to its display-URL alias.
#
# Hyrax::RedirectToDisplayUrl only carries `locale` across the redirect. The
# show pages build their own links (sort, per page, pagination, the work Items
# pager) from the ID URL, so following any of them 301s back to the alias with
# those params dropped, e.g. /collections/<id>?sort=title_ssi+asc lands on
# /ulpa_1980_020?locale=en, unsorted.
#
# The params are rebuilt with #to_query, so values stay encoded and can't
# inject extra params into the Location header.
module Hyrax
  module RedirectToDisplayUrlQueryDecorator
    private

    def with_locale(path)
      query = request.query_parameters
      return super if query.blank?
      separator = path.include?('?') ? '&' : '?'
      "#{path}#{separator}#{query.to_query}"
    end
  end
end

Hyrax::RedirectToDisplayUrl.prepend(Hyrax::RedirectToDisplayUrlQueryDecorator) unless Hyrax::RedirectToDisplayUrl < Hyrax::RedirectToDisplayUrlQueryDecorator
