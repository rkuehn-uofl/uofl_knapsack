# frozen_string_literal: true

# UOFL OVERRIDE: Fully restore Wings after Rails development reloads unload the namespace.
module HykuKnapsack
  module WingsReloaderDecorator
    module_function

    def call
      return if Hyrax.config.disable_wings

      reload_wings_if_unloaded
      register_model_mappings
    end

    def reload_wings_if_unloaded
      return if defined?(::Wings::ModelRegistry) && defined?(::Wings::Valkyrie::MetadataAdapter)

      hyrax_lib_path = Gem.loaded_specs.fetch("hyrax").full_gem_path + "/lib/"
      $LOADED_FEATURES.delete_if do |feature|
        feature.start_with?(hyrax_lib_path + "wings.rb") || feature.start_with?(hyrax_lib_path + "wings/")
      end

      %i[BuffaloWings MightyWings HotWings SpicyWings SwissWings BuffaloCauliflowerWings].each do |const_name|
        Object.send(:remove_const, const_name) if Object.const_defined?(const_name, false)
      end

      require "wings"
    end

    def register_model_mappings
      # Text is a native Valkyrie resource (see app/models/text.rb) with no
      # legacy ActiveFedora counterpart, so it's intentionally excluded here.
      # Registering it as its own "legacy model" makes Hyrax::ResourceName's
      # lookup point back at Text itself, and calling Text.model_name recurses
      # forever (SystemStackError) trying to resolve its own route keys.
      [AdminSet, Collection, Etd, GenericWork, Image, Oer].each do |klass|
        resource_klass = "#{klass}Resource".safe_constantize
        ::Wings::ModelRegistry.register(resource_klass, klass) if resource_klass
        ::Wings::ModelRegistry.register(klass, klass)
      end

      ::Wings::ModelRegistry.register(FileSet, FileSet)
      ::Wings::ModelRegistry.register(Hyrax::FileSet, FileSet)
      ::Wings::ModelRegistry.register(Hydra::PCDM::File, Hydra::PCDM::File)
      ::Wings::ModelRegistry.register(Hyrax::FileMetadata, Hydra::PCDM::File)
    end
  end
end

HykuKnapsack::WingsReloaderDecorator.call
