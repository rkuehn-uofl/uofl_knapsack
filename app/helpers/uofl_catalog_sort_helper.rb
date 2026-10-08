# frozen_string_literal: true

# UOFL OVERRIDE NEW FILE: backs app/views/themes/uofl/catalog/_sort_widget.html.erb.
#
# CatalogControllerSortFieldsDecorator registers a separate ascending and
# descending Blacklight sort_field for Title/Date added/Item Number (so
# Blacklight can still parse an incoming ?sort= param and know which
# direction is currently active). This helper collapses each asc/desc pair
# into a single dropdown row whose text names the direction that clicking it
# will apply next, so once a row is the active sort it flips to offer the
# opposite direction. A row that isn't the active sort shows its default
# first-click direction.
module UoflCatalogSortHelper
  SORT_TOGGLE_GROUPS = [
    { asc: "title_ssi asc", desc: "title_ssi desc",
      asc_label: "Title (A-Z)", desc_label: "Title (Z-A)", default: :asc },
    { asc: "system_create_dtsi asc", desc: "system_create_dtsi desc",
      asc_label: "Date added (oldest-most recent)", desc_label: "Date added (most recent-oldest)", default: :desc },
    { asc: "source_identifier_ssi asc", desc: "source_identifier_ssi desc",
      asc_label: "Item Number (A-Z)", desc_label: "Item Number (Z-A)", default: :asc }
  ].freeze

  RELEVANCE_KEY = "score desc, system_create_dtsi desc"

  # @return [Array<Array(String, String, Boolean)>] [label, sort value, active?] rows
  def uofl_sort_choices
    current_key = current_sort_field&.key

    [
      ["Relevance", RELEVANCE_KEY, current_key == RELEVANCE_KEY],
      *SORT_TOGGLE_GROUPS.map { |group| uofl_toggle_choice(group, current_key) }
    ]
  end

  # The dropdown button's own label, shown when closed -- unlike the menu
  # rows, this names the sort actually in effect right now, not the toggle
  # target.
  def uofl_current_sort_label
    current_key = current_sort_field&.key
    return "Relevance" if current_key.blank? || current_key == RELEVANCE_KEY

    group = SORT_TOGGLE_GROUPS.find { |g| g[:asc] == current_key || g[:desc] == current_key }
    return current_key.to_s unless group

    current_key == group[:asc] ? group[:asc_label] : group[:desc_label]
  end

  private

  def uofl_toggle_choice(group, current_key)
    if current_key == group[:asc]
      [group[:desc_label], group[:desc], true]
    elsif current_key == group[:desc]
      [group[:asc_label], group[:asc], true]
    elsif group[:default] == :asc
      [group[:asc_label], group[:asc], false]
    else
      [group[:desc_label], group[:desc], false]
    end
  end
end
