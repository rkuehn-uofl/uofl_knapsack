# frozen_string_literal: true

module HykuKnapsack
  module DownloadsControllerDecorator
    private

    # UOFL OVERRIDE: Resolve Valkyrie FileSet thumbnail ids before falling back to
    # the legacy Wings alternate-id lookup used for ActiveFedora file sets.
    def file_set_parent(file_set_id)
      @parent ||=
        case (file_set = download_file_set(file_set_id))
        when Hyrax::Resource
          Hyrax.query_service.find_parents(resource: file_set).first
        else
          file_set.parent
        end
    end

    def download_file_set(file_set_id)
      freyja_download_file_set(file_set_id) || Hyrax.query_service.find_by(id: file_set_id)
    rescue Hyrax::ObjectNotFoundError, Valkyrie::Persistence::ObjectNotFoundError
      legacy_download_file_set(file_set_id)
    end

    def freyja_download_file_set(file_set_id)
      return unless Valkyrie::MetadataAdapter.adapters.include?(:freyja)

      Valkyrie::MetadataAdapter.find(:freyja).query_service.find_by(id: file_set_id)
    rescue Hyrax::ObjectNotFoundError, Valkyrie::Persistence::ObjectNotFoundError
      nil
    end

    def legacy_download_file_set(file_set_id)
      wings_adapter = begin
        defined?(Wings::Valkyrie::MetadataAdapter) && Wings::Valkyrie::MetadataAdapter
                      rescue NameError
                        nil
      end

      if wings_adapter && Hyrax.metadata_adapter.is_a?(wings_adapter)
        Hyrax.query_service.find_by_alternate_identifier(
          alternate_identifier: file_set_id,
          use_valkyrie: Hyrax.config.use_valkyrie?
        )
      else
        Hyrax.query_service.find_by(id: file_set_id)
      end
    end
  end
end

Hyrax::DownloadsControllerDecorator.prepend(HykuKnapsack::DownloadsControllerDecorator) if defined?(Hyrax::DownloadsControllerDecorator)
Hyrax::DownloadsController.prepend(HykuKnapsack::DownloadsControllerDecorator)
