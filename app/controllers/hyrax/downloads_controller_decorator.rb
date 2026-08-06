# frozen_string_literal: true

module HykuKnapsack
  module DownloadsControllerDecorator
    private

    # UOFL OVERRIDE: Resolve Valkyrie FileSet thumbnail ids via query_service.
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
      Hyrax.query_service.find_by(id: file_set_id)
    end
  end
end

Hyrax::DownloadsControllerDecorator.prepend(HykuKnapsack::DownloadsControllerDecorator) if defined?(Hyrax::DownloadsControllerDecorator)
Hyrax::DownloadsController.prepend(HykuKnapsack::DownloadsControllerDecorator)
