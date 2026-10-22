# frozen_string_literal: true

# UOFL OVERRIDE NEW FILE: Decide when an import run is finished from its
# entries' statuses instead of the run's enqueued_records counter.
#
# Upstream Bulkrax 9.5.1 only marks an importer Complete when
# enqueued_records lands on exactly 0, but that counter drifts: the parser
# queues each job before incrementing it, increments it with a
# read-modify-write save that can overwrite a job's decrement, and the jobs'
# "decrement unless <= 0" guard is check-then-act. A run whose entries are all
# Complete can be left with enqueued_records > 0 and stay "Pending" forever.
#
# Every entry already gets a "Pending" status for the run when it is queued
# and a final status when its job ends, so a run is finished when:
# 1. queueing has finished: ImporterJob writes a "Pending" importer status for
#    the run once the parser has queued every entry (see
#    importer_job_record_status_decorator.rb); before that, jobs finishing
#    early must not mark the run done.
# 2. no entry's latest status for this run is still "Pending".
module Bulkrax
  module ImporterRecordStatusDecorator
    QUEUED_MARKER = 'Pending'

    def record_status
      record_status_for(ImporterRun.find(current_run.id)) # make sure fresh
    end

    # Called by ImporterJob once the parser has queued every entry.
    def mark_queueing_finished(importer_run)
      set_status_info(QUEUED_MARKER, importer_run)
    end

    # @param assume_queued [Boolean] skip the queueing-finished check, for
    #   repairing runs that predate the marker.
    def record_status_for(importer_run, assume_queued: false)
      return if validate_only
      return unless assume_queued || queueing_finished?(importer_run)

      latest = latest_entry_statuses(importer_run)
      return if latest[QUEUED_MARKER].to_i.positive? # still processing

      importer_run.update_columns(enqueued_records: 0) unless importer_run.enqueued_records.zero? # rubocop:disable Rails/SkipsModelValidations
      set_status_info(final_status(importer_run, latest), importer_run)
    end

    def queueing_finished?(importer_run)
      statuses.where(runnable: importer_run, status_message: QUEUED_MARKER).exists?
    end

    # @return [Hash{String => Integer}] status_message => number of entries
    #   whose most recent status for this run has that message
    def latest_entry_statuses(importer_run)
      for_run = Bulkrax::Status.where(statusable_type: 'Bulkrax::Entry', runnable: importer_run)
      latest_ids = for_run.group(:statusable_id).maximum(:id).values
      Bulkrax::Status.where(id: latest_ids).group(:status_message).count
    end

    private

    # Same outcomes as upstream record_status, plus failed entries counting
    # as failures.
    def final_status(importer_run, latest)
      return 'Complete' unless importer_run.failed_records.positive? || latest['Failed'].to_i.positive?
      return 'Complete (with failures)' if importer_run.invalid_records.blank?

      Bulkrax::ImportFailed.new('Failed with Invalid Records', importer_run.invalid_records.split("\n"))
    end
  end
end

Bulkrax::Importer.prepend(Bulkrax::ImporterRecordStatusDecorator)
