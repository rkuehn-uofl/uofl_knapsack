# frozen_string_literal: true

# UOFL OVERRIDE NEW FILE: Give each Bulkrax-imported work and collection a
# default redirect alias built from an env-configured path template when the
# CSV row has no redirect columns.
module Bulkrax
  # rubocop:disable Metrics/ModuleLength
  module BulkraxDefaultRedirectDecorator
    DEFAULT_REDIRECT_PATH_TEMPLATE = '/{source_identifier}'
    DEFAULT_REDIRECT_PLACEHOLDER = /\{\s*([^{}\s]+)\s*\}/

    # Supported env vars:
    # - BULKRAX_DEFAULT_REDIRECT_ENABLED: set to true, 1, yes, or on to add the
    #   default alias
    # - BULKRAX_DEFAULT_REDIRECT_PATH: the alias path template. Defaults to
    #   "/{source_identifier}". Placeholders:
    #   - {model}: the work type, e.g. "image" for ImageResource, "text" for Text
    #   - {any_field}: the row's value for that field, read from the work
    #     property, then a property mapped from a CSV column of that name, then
    #     the raw CSV column
    #   Placeholder values are lowercased with whitespace replaced by
    #   underscores, so "/image/{source_identifier}" with Item number
    #   "ULPA 1972_001_01" becomes "/image/ulpa_1972_001_01". Literal text is
    #   kept as written.
    # - BULKRAX_DEFAULT_REDIRECT_COLLECTION_PATH: optional template for
    #   collections, with the same placeholders ({model} is "collection").
    #   Defaults to BULKRAX_DEFAULT_REDIRECT_PATH.
    # - BULKRAX_DEFAULT_REDIRECT_IS_DISPLAY_URL: set to true, 1, yes, or on to
    #   make the default alias the work's display URL (only when the work has
    #   no other display URL)
    #
    # Each imported work or collection gets:
    # - the CSV's redirect_path_<n> aliases, when the row has any (no default)
    # - otherwise its existing aliases plus the default alias
    # - nothing new when the default alias is already on the work, a
    #   placeholder has no value, or the path is reserved or claimed by another
    #   record (a collision would fail the whole row)
    def transform_attributes(update: false)
      attrs = super
      redirects_attributes = default_redirects_attributes_for(attrs)
      return attrs if redirects_attributes.blank?

      attrs.merge(redirects_attributes:)
    end

    private

    def default_redirects_attributes_for(attrs)
      return unless default_redirect_applicable?
      return if import_row_redirect_paths?(attrs)

      path = default_redirect_path(attrs)
      return if path.blank?

      existing = existing_redirects
      return if existing.any? { |entry| entry['path'] == path }
      return if default_redirect_unavailable?(path)

      entries = existing + [{ 'path' => path, 'is_display_url' => default_redirect_display_url?(existing) }]
      entries.each_with_index.to_h do |entry, index|
        [index.to_s, { 'path' => entry['path'], 'is_display_url' => entry['is_display_url'].to_s, '_destroy' => 'false' }]
      end
    end

    def default_redirect_applicable?
      return false unless truthy_redirect_env?('BULKRAX_DEFAULT_REDIRECT_ENABLED')
      # Hyrax versions without the redirects feature have no redirects_active?.
      return false unless Hyrax.config.respond_to?(:redirects_active?) && Hyrax.config.redirects_active?
      return false if klass == Bulkrax.file_model_class

      permitted_attributes.map(&:to_sym).include?(:redirects)
    end

    def import_row_redirect_paths?(attrs)
      rows = attrs[:redirects_attributes] || attrs['redirects_attributes']
      rows = rows.values if rows.respond_to?(:values)

      Array.wrap(rows).any? do |row|
        row.respond_to?(:[]) && Array.wrap(row['path'] || row[:path]).any?(&:present?)
      end
    end

    # Fills the template's placeholders. Returns nil when any placeholder has
    # no value, so a half-built alias like "/image/" is never saved.
    def default_redirect_path(attrs)
      missing = []
      path = default_redirect_path_template.gsub(DEFAULT_REDIRECT_PLACEHOLDER) do
        field = Regexp.last_match(1)
        slug = default_redirect_slug(default_redirect_value_for(field, attrs))
        missing << field if slug.blank?
        slug
      end

      if missing.any?
        Rails.logger.warn("[Bulkrax] Skipped default redirect for #{try(:source_identifier_value)}: " \
                          "no value for #{missing.uniq.join(', ')}")
        return
      end

      path = "/#{path}".squeeze('/').chomp('/')
      path unless path == '/'
    end

    def default_redirect_path_template
      collection_template = ENV.fetch('BULKRAX_DEFAULT_REDIRECT_COLLECTION_PATH', '').strip.presence
      return collection_template if collection_template && klass == Bulkrax.collection_model_class

      ENV.fetch('BULKRAX_DEFAULT_REDIRECT_PATH', '').strip.presence || DEFAULT_REDIRECT_PATH_TEMPLATE
    end

    def default_redirect_slug(value)
      value.to_s.strip.downcase.gsub(/\s+/, '_').gsub(/[^a-z0-9\-._~]/, '')
    end

    def default_redirect_value_for(field, attrs)
      return default_redirect_model_name if field == 'model'

      default_redirect_attribute_value(attrs, field) ||
        default_redirect_attribute_value(attributes, field) ||
        default_redirect_mapped_value_for(field) ||
        default_redirect_raw_csv_value_for(field) ||
        (try(:source_identifier_value) if field == 'source_identifier')
    end

    # "ImageResource" => "image", "GenericWorkResource" => "generic_work",
    # "CollectionResource" => "collection"
    def default_redirect_model_name
      klass.to_s.demodulize.underscore.delete_suffix('_resource')
    end

    def default_redirect_attribute_value(source, field)
      return if source.blank?

      Array.wrap(source[field] || source[field.to_sym]).find(&:present?)
    end

    # The value of any property mapped from a CSV column named `field`.
    def default_redirect_mapped_value_for(field)
      target_fields = Bulkrax.field_mappings.values.flat_map do |parser_mapping|
        parser_mapping.filter_map do |target_field, config|
          next unless config.respond_to?(:[])

          from_fields = Array.wrap(config['from'] || config[:from]).map(&:to_s)
          target_field.to_s if from_fields.include?(field)
        end
      end

      target_fields.uniq.lazy.map { |target_field| default_redirect_attribute_value(attributes, target_field) }.find(&:present?)
    end

    # The entry's raw CSV row, for columns Bulkrax doesn't map to a property.
    def default_redirect_raw_csv_value_for(field)
      default_redirect_attribute_value(default_redirect_raw_metadata, field)
    end

    def default_redirect_raw_metadata
      return @default_redirect_raw_metadata if defined?(@default_redirect_raw_metadata)

      importer_run_id = try(:importer_run_id)
      @default_redirect_raw_metadata = if importer_run_id.present? && try(:source_identifier_value).present?
                                         importer = Bulkrax::ImporterRun.find_by(id: importer_run_id)&.importer
                                         importer&.entries&.find_by(identifier: source_identifier_value)
                                                 &.raw_metadata&.to_h
                                       end
    end

    # The work's saved aliases, normalized to string keys. Empty on create.
    def existing_redirects
      Array.wrap(object.try(:redirects)).filter_map do |entry|
        entry = entry.to_h.stringify_keys
        next if entry['path'].blank?

        { 'path' => entry['path'], 'is_display_url' => entry['is_display_url'].to_s == 'true' }
      end
    end

    def default_redirect_unavailable?(path)
      reason = if Hyrax.config.reserved_redirect_prefixes.any? { |prefix| path == prefix || path.start_with?("#{prefix}/") }
                 'is reserved'
               elsif Hyrax::RedirectsLookup.taken?(path, except_id: object.try(:id)&.to_s)
                 'is already used by another record'
               end
      return false if reason.nil?

      Rails.logger.warn("[Bulkrax] Skipped default redirect #{path} for #{try(:source_identifier_value)}: #{reason}")
      true
    end

    def default_redirect_display_url?(existing)
      truthy_redirect_env?('BULKRAX_DEFAULT_REDIRECT_IS_DISPLAY_URL') &&
        existing.none? { |entry| entry['is_display_url'] }
    end

    def truthy_redirect_env?(key)
      %w[true 1 yes on].include?(ENV.fetch(key, '').to_s.strip.downcase)
    end
  end
  # rubocop:enable Metrics/ModuleLength
end

Bulkrax::ValkyrieObjectFactory.prepend(Bulkrax::BulkraxDefaultRedirectDecorator)
