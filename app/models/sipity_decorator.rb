# frozen_string_literal: true

# UOFL OVERRIDE: Sipity::Entity() (hyrax-webapp/app/models/sipity.rb) logs several
# Hyrax.logger.debug("...#{input.inspect}...") calls using eager string
# interpolation rather than the block form. Ruby builds that string on every call
# regardless of whether debug-level logging is enabled, and `input`/`result` here
# are frequently a SolrDocument or Valkyrie::Resource carrying a full
# extracted-text field (hundreds of KB for scanned PDFs/OCR'd text) - #inspect
# serializes the whole thing. Measured in production: a single
# Hyrax::TextsController#show request logged 101 Entity() calls, ~40 of them
# dumping ~53KB apiece, and took 355 seconds - almost entirely in view
# rendering, not Solr or the database. This override keeps the exact same
# conversion logic and moves the same messages behind block-form logging
# (skipped entirely unless debug logging is on) and swaps #inspect on
# input/result for a cheap class/id label, since nothing was reading the full
# object dump anyway.
module Sipity
  # rubocop:disable Naming/MethodName, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
  def Entity(input, &block)
    Hyrax.logger.debug { "Trying to make an Entity for #{entity_debug_label(input)}" }

    result = case input
             when Sipity::Entity
               input
             when URI::GID, GlobalID
               Hyrax.logger.debug { "Entity() got a GID, searching by proxy" }
               gid_string = input.to_s
               Hyrax.logger.debug { "  Searching for GID: #{gid_string}" }
               entity_find_by_gid(input, gid_string)
             when SolrDocument
               if Hyrax.config.disable_wings
                 # In no-Wings mode, resolve via query_service instead of
                 # SolrDocument#to_model, which can trigger ActiveFedora/Fedora lookups.
                 item = Hyrax.query_service.find_by(id: input.id)
                 Hyrax.logger.debug { "Entity() got a SolrDocument in valkyrie/no-wings mode, retrying on item #{item.id}" }
                 Entity(item)
               else
                 model = input.to_model
                 Hyrax.logger.debug { "Entity() got a SolrDocument, retrying on #{model}" }
                 Entity(model)
               end
             when Draper::Decorator
               Hyrax.logger.debug { "Entity() got a Decorator, retrying on #{input.model}" }
               Entity(input.model)
             when Sipity::Comment
               Hyrax.logger.debug { "Entity() got a Comment, retrying on #{input.entity}" }
               Entity(input.entity)
             when Valkyrie::Resource
               Hyrax.logger.debug { "Entity() got a Resource, retrying on #{Hyrax::GlobalID(input)}" }
               Entity(Hyrax::GlobalID(input))
             else
               Hyrax.logger.debug { "Entity() got something else (#{input.class}), testing #to_global_id" }
               if input.respond_to?(:to_global_id)
                 the_gid_obj = input.to_global_id
                 Hyrax.logger.debug { "  Generated GID object: #{the_gid_obj.inspect}" }
                 Hyrax.logger.debug { "  Calling Entity recursively with GID object." }
                 Entity(the_gid_obj)
               end
             end

    Hyrax.logger.debug { "Entity(): attempting conversion on input: #{entity_debug_label(input)} with result: #{entity_debug_label(result)}" }
    handle_conversion(input, result, :to_sipity_entity, &block)
  rescue URI::GID::MissingModelIdError
    Entity(nil)
  end
  module_function :Entity
  # rubocop:enable Naming/MethodName, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

  # Cheap stand-in for #inspect in Entity() debug logging - input/result here are
  # often a SolrDocument or Valkyrie::Resource carrying a full extracted-text
  # field, and #inspect serializes the entire thing.
  def entity_debug_label(obj)
    return obj.inspect if obj.nil? || obj.is_a?(String) || obj.is_a?(Symbol) || obj.is_a?(Numeric) || obj == true || obj == false

    obj.respond_to?(:id) ? "#{obj.class}(#{obj.id})" : obj.class.to_s
  end
  module_function :entity_debug_label
end
