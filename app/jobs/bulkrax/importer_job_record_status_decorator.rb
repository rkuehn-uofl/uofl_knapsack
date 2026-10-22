# frozen_string_literal: true

# UOFL OVERRIDE NEW FILE: Once the parser has queued every entry, mark the run
# as fully queued and check whether it is already finished. Pairs with
# importer_record_status_decorator.rb, which won't mark a run done until this
# marker exists, so jobs that finish while the parser is still queueing can't
# close the run early. The check here covers the case where every job has
# already finished by the time queueing ends, so no later job would record the
# status.
module Bulkrax
  module ImporterJobRecordStatusDecorator
    private

    def import(importer, only_updates_since_last_import)
      super.tap do
        run = importer.current_run
        next if importer.validate_only
        # valid_import? and import_objects record a Failed status for the run
        # when they bail out; that run never queued its entries.
        next if importer.statuses.where(runnable: run, status_message: 'Failed').exists?

        importer.mark_queueing_finished(run)
        importer.record_status_for(Bulkrax::ImporterRun.find(run.id))
      end
    end
  end
end

Bulkrax::ImporterJob.prepend(Bulkrax::ImporterJobRecordStatusDecorator)
