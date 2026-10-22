# frozen_string_literal: true

# UOFL OVERRIDE NEW FILE: Cover importer status being decided from entry
# statuses rather than the enqueued_records counter.
RSpec.describe Bulkrax::ImporterRecordStatusDecorator do
  let(:importer) { FactoryBot.create(:bulkrax_importer_oer_csv, limit: nil) }
  let(:run) { importer.importer_runs.create! }
  let(:entries) do
    Array.new(3) { |i| Bulkrax::CsvEntry.create!(identifier: "entry-#{i}", importerexporter: importer, raw_metadata: {}) }
  end

  before { importer.current_run = run }

  # What the parser does for each row: a Pending status for the run, then the job.
  def queue(entry_list, importer_run = run)
    entry_list.each { |e| e.set_status_info('Pending', importer_run) }
  end

  def finish(entry_list, message = nil, importer_run = run)
    entry_list.each { |e| e.set_status_info(message, importer_run) }
  end

  def importer_messages
    importer.statuses.where(runnable: run).order(:id).pluck(:status_message)
  end

  describe '#record_status' do
    before { queue(entries) }

    context 'when queueing has finished' do
      before { importer.mark_queueing_finished(run) }

      it 'marks the run Complete when every entry is done, whatever enqueued_records says' do
        run.update!(enqueued_records: 7)
        finish(entries)

        importer.record_status

        expect(importer.reload.status_message).to eq('Complete')
        expect(importer.status).to eq('Complete')
        expect(run.reload.enqueued_records).to eq(0)
      end

      it 'stays Pending while any entry is still Pending' do
        run.update!(enqueued_records: 0)
        finish(entries.first(2))

        importer.record_status

        expect(importer_messages).to eq(['Pending'])
        expect(importer.reload.status_message).to eq('Pending')
      end

      it 'records Complete (with failures) when an entry failed' do
        finish(entries.first(2))
        finish([entries.last], StandardError.new('boom'))

        importer.record_status

        expect(importer.reload.status_message).to eq('Complete (with failures)')
      end

      it 'records Failed when the run has invalid records' do
        finish(entries)
        run.update!(failed_records: 1, invalid_records: "Missing source_identifier for {}\n")

        importer.record_status

        expect(importer.reload.status_message).to eq('Failed')
        expect(importer.last_error[:error_class]).to eq('Bulkrax::ImportFailed')
      end

      it 'ignores entries left Pending by an earlier run' do
        earlier = importer.importer_runs.create!
        lost = Bulkrax::CsvEntry.create!(identifier: 'lost', importerexporter: importer, raw_metadata: {})
        queue([lost], earlier)
        finish(entries)

        importer.record_status

        expect(importer.reload.status_message).to eq('Complete')
      end
    end

    context 'while the parser is still queueing' do
      it 'does not mark the run done even if every queued entry has finished' do
        run.update!(enqueued_records: 0)
        finish(entries)

        importer.record_status

        expect(importer_messages).to be_empty
        expect(importer.status).to eq('Pending')
      end
    end

    it 'leaves validate-only importers alone' do
      importer.update!(validate_only: true)
      importer.mark_queueing_finished(run)
      finish(entries)

      importer.record_status

      expect(importer_messages).to eq(['Pending'])
    end
  end

  describe 'Bulkrax::ImporterJob#import' do
    subject(:import) { Bulkrax::ImporterJob.new.send(:import, importer, false) }

    before { allow(importer).to receive(:valid_import?).and_return(true) }

    it 'marks queueing finished and records Complete when every job already finished' do
      allow(importer).to receive(:import_objects) do
        queue(entries)
        finish(entries)
      end

      import

      expect(importer_messages).to eq(%w[Pending Complete])
      expect(importer.reload.status_message).to eq('Complete')
    end

    it 'marks queueing finished but stays Pending while jobs are still running' do
      allow(importer).to receive(:import_objects) { queue(entries) }

      import

      expect(importer_messages).to eq(['Pending'])
      expect(importer.queueing_finished?(run)).to be(true)
    end

    it 'lets the last job to finish record Complete after queueing' do
      allow(importer).to receive(:import_objects) { queue(entries) }
      import
      finish(entries)

      Bulkrax::Importer.find(importer.id).tap { |i| i.current_run = run }.record_status

      expect(importer.reload.status_message).to eq('Complete')
    end

    it 'does not mark queueing finished when the import failed before queueing' do
      allow(importer).to receive(:import_objects) { importer.set_status_info(StandardError.new('bad csv'), run) }

      import

      expect(importer_messages).to eq(['Failed'])
      expect(importer.queueing_finished?(run)).to be(false)
    end
  end
end
