# frozen_string_literal: true

# UOFL OVERRIDE NEW FILE: Generate and update FileSet alt text during Bulkrax imports.
module Bulkrax
  # rubocop:disable Metrics/ModuleLength
  module BulkraxFileSetAltTextDecorator
    def run!
      super.tap do |resource|
        sync_persisted_file_set_alt_text(resource)
      end
    end

    private

    # Build FileSet alt text from env-configured parts so institutions can
    # change the formula without changing code.
    #
    # Supported env vars:
    # - BULKRAX_FILESET_ALT_TEXT_ENABLED: set to true, 1, yes, or on to populate alt text
    # - BULKRAX_FILESET_ALT_TEXT_FIELDS: comma-separated fields used to build alt text
    # - BULKRAX_FILESET_ALT_TEXT_SEPARATOR: text placed between field values
    # - BULKRAX_FILESET_ALT_TEXT_SUFFIX: optional phrase appended to generated alt text
    def file_set_params_for(uploads:, files:)
      return super unless file_set_alt_text_enabled?

      super.map.with_index do |params, index|
        next params if file_set_alt_text_present?(params)

        file_name = file_name_from_sources(params, files[index], uploads[index])
        file_alt_text = generated_alt_text(file_name:)

        next params if file_alt_text.blank?

        params.merge(alt_text: [file_alt_text])
      end
    end

    def sync_persisted_file_set_alt_text(resource)
      return unless file_set_alt_text_enabled?
      return if resource.blank?
      return if resource.class == Bulkrax.collection_model_class

      updated_file_sets = persisted_file_sets_for(resource).filter_map.with_index do |file_set, index|
        sync_persisted_file_set_alt_text_for(file_set, index)
      end

      return if updated_file_sets.blank?

      self.class.update_index(resources: [resource])
    end

    def persisted_file_sets_for(resource)
      return [resource] if resource.class == Bulkrax.file_model_class

      self.class.file_sets_for(resource:)
    end

    def sync_persisted_file_set_alt_text_for(file_set, index)
      return unless file_set.respond_to?(:alt_text=)

      file_name = persisted_file_set_name(file_set, index)
      file_alt_text = generated_alt_text(file_name:)

      return if file_alt_text.blank?
      return if Array.wrap(file_set.try(:alt_text)) == [file_alt_text]

      file_set.alt_text = [file_alt_text]
      self.class.save!(resource: file_set, user:)
    end

    def persisted_file_set_name(file_set, index)
      file_name_from_sources(parsed_file_values[index], file_set.try(:title), original_file_name_for(file_set))
    end

    def parsed_file_values
      @parsed_file_values ||= Array.wrap(attributes['file'] || attributes[:file])
    end

    def original_file_name_for(file_set)
      self.class.filename_for(fileset: file_set)
    rescue NoMethodError, Valkyrie::Persistence::ObjectNotFoundError
      nil
    end

    def generated_alt_text(file_name:)
      parts = alt_text_fields.filter_map do |field|
        alt_text_value_for(field, file_name:)
      end
      parts << alt_text_suffix if alt_text_suffix.present?

      alt_text = parts.join(alt_text_separator).strip

      alt_text.presence
    end

    def file_set_alt_text_enabled?
      truthy_env?('BULKRAX_FILESET_ALT_TEXT_ENABLED')
    end

    def truthy_env?(key)
      %w[true 1 yes on].include?(ENV.fetch(key, '').to_s.strip.downcase)
    end

    def file_set_alt_text_present?(params)
      Array.wrap(params.with_indifferent_access[:alt_text]).any?(&:present?)
    end

    def alt_text_fields
      ENV.fetch('BULKRAX_FILESET_ALT_TEXT_FIELDS', 'file_name')
         .split(',')
         .map(&:strip)
         .reject(&:blank?)
    end

    def alt_text_separator
      ENV.fetch('BULKRAX_FILESET_ALT_TEXT_SEPARATOR', ' ')
    end

    def alt_text_suffix
      ENV.fetch('BULKRAX_FILESET_ALT_TEXT_SUFFIX', '').to_s
    end

    def alt_text_value_for(field, file_name:)
      normalized_field = field.to_s.strip

      case normalized_field.downcase
      when 'file', 'file_name'
        file_name
      when 'file_name_without_extension'
        file_name_without_extension(file_name)
      else
        direct_attribute_value_for(normalized_field) || mapped_attribute_value_for(normalized_field)
      end
    end

    def direct_attribute_value_for(field)
      Array.wrap(attributes[field] || attributes[field.to_sym]).find(&:present?)
    end

    def mapped_attribute_value_for(source_field)
      mapped_attribute_fields_for(source_field).lazy.map do |target_field|
        direct_attribute_value_for(target_field)
      end.find(&:present?)
    end

    def mapped_attribute_fields_for(source_field)
      normalized_source = source_field.to_s.strip.downcase

      bulkrax_field_mappings.values.flat_map do |parser_mapping|
        parser_mapping.filter_map do |target_field, config|
          from_fields = Array.wrap(config['from'] || config[:from]).map { |value| value.to_s.strip.downcase }
          target_field.to_s if from_fields.include?(normalized_source)
        end
      end.uniq
    end

    def bulkrax_field_mappings
      Bulkrax.field_mappings.with_indifferent_access
    end

    def file_name_from_sources(*sources)
      file_name = sources.filter_map { |source| file_name_from(source) }.first
      return if file_name.blank?

      File.basename(file_name.to_s)
    end

    def file_name_without_extension(file_name)
      return if file_name.blank?

      File.basename(file_name.to_s, File.extname(file_name.to_s))
    end

    def file_name_from(source)
      return if source.blank?
      return first_present_array_value(source) if source.is_a?(Array)
      return source if source.is_a?(String)
      return file_name_from_hash(source) if source.respond_to?(:key?)

      source.try(:original_filename) || source.try(:path) || source.to_s
    end

    def file_name_from_hash(source)
      first_present_array_value(source[:file] || source['file']) ||
        source[:path] || source['path'] ||
        source[:url] || source['url'] ||
        first_present_array_value(source[:title] || source['title'])
    end

    def first_present_array_value(value)
      Array.wrap(value).find(&:present?)
    end
  end
  # rubocop:enable Metrics/ModuleLength
end

Bulkrax::ValkyrieObjectFactory.prepend(Bulkrax::BulkraxFileSetAltTextDecorator)
