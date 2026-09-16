# frozen_string_literal: true

# UOFL OVERRIDE NEW FILE: backs app/views/themes/uofl/catalog/_sort_widget.html.erb.
#
# CatalogControllerDecorator#configure_uofl_sort_fields registers a separate
# ascending and descending Blacklight sort_field for Title/Date Uploaded/Date
# Modified (so Blacklight can still parse an incoming ?sort= param and know
# which direction is currently active). This helper collapses each asc/desc
# pair into a single dropdown row: the label's arrow shows the direction that
# clicking it will apply next, not the field's current direction, so once a
# row is the active sort its own arrow flips to offer the opposite direction
# while every other row keeps its default (descending-first) arrow.
module UoflCatalogSortHelper
  SORT_TOGGLE_GROUPS = [
    { label: "Title", asc: "title_ssi asc", desc: "title_ssi desc" },
    { label: "Date Uploaded", asc: "system_create_dtsi asc", desc: "system_create_dtsi desc" },
    { label: "Date Modified", asc: "system_modified_dtsi asc", desc: "system_modified_dtsi desc" }
  ].freeze

  RELEVANCE_KEY = "score desc, system_create_dtsi desc"
  ITEM_NUMBER_KEY = "source_identifier_ssi asc"

  # @return [Array<Array(String, String, Boolean)>] [label, sort value, active?] rows
  def uofl_sort_choices
    current_key = current_sort_field&.key

    [
      ["Relevance", RELEVANCE_KEY, current_key == RELEVANCE_KEY],
      *SORT_TOGGLE_GROUPS.map { |group| uofl_toggle_choice(group, current_key) },
      ["Item Number", ITEM_NUMBER_KEY, current_key == ITEM_NUMBER_KEY]
    ]
  end

  # The dropdown button's own label, shown when closed -- unlike the menu
  # rows, this reflects the sort actually in effect right now (so the button
  # reads e.g. "Title ▼" while sorted title_ssi desc), not the toggle target.
  def uofl_current_sort_label
    current_key = current_sort_field&.key
    return "Relevance" if current_key.blank? || current_key == RELEVANCE_KEY
    return "Item Number" if current_key == ITEM_NUMBER_KEY

    group = SORT_TOGGLE_GROUPS.find { |g| g[:asc] == current_key || g[:desc] == current_key }
    return current_key.to_s unless group

    "#{group[:label]} #{current_key == group[:desc] ? "▼" : "▲"}"
  end

  private

  def uofl_toggle_choice(group, current_key)
    if current_key == group[:desc]
      ["#{group[:label]} ▲", group[:asc], true]
    elsif current_key == group[:asc]
      ["#{group[:label]} ▼", group[:desc], true]
    else
      ["#{group[:label]} ▼", group[:desc], false]
    end
  end
end
