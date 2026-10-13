# frozen_string_literal: true

# UOFL OVERRIDE NEW FILE: Remove a record's redirect aliases when Bulkrax
# deletes it. Upstream Bulkrax 9.5.1 deletes via Hyrax.persister.delete
# directly, skipping Hyrax's destroy transactions and their
# remove_redirect_paths step. Without this, a record deleted by Bulkrax (a
# delete, or "Remove and Rerun") leaves its rows in hyrax_redirect_paths, the
# old aliases keep claiming their paths, and the re-created record can't use
# them.
module Bulkrax
  module ValkyrieObjectFactoryRemoveRedirectsDecorator
    def delete(user)
      resource = find
      super.tap { remove_redirect_paths_for(resource) }
    end

    private

    def remove_redirect_paths_for(resource)
      return if resource.blank?
      # Hyrax versions without the redirects feature have no such step.
      return unless defined?(Hyrax::Transactions::Steps::RemoveRedirectPaths)

      Hyrax::Transactions::Steps::RemoveRedirectPaths.new.call(resource).value_or do |failure|
        Rails.logger.warn("[Bulkrax] Could not remove redirect aliases for deleted #{resource.id}: #{failure.inspect}")
      end
    end
  end
end

Bulkrax::ValkyrieObjectFactory.prepend(Bulkrax::ValkyrieObjectFactoryRemoveRedirectsDecorator)
