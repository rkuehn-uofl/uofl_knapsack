# frozen_string_literal: true

namespace :hyku_knapsack do
  namespace :bulkrax do
    desc 'Re-check importers still labelled "Pending" and record their real status from their latest run\'s entry ' \
         'statuses. Fixes runs left Pending by the enqueued_records counter race (see ' \
         'app/models/bulkrax/importer_record_status_decorator.rb). A run with any entry still Pending is left alone. ' \
         'Do not run while an import is still queueing. DRY_RUN=true reports without writing. ' \
         'Usage: rake "hyku_knapsack:bulkrax:repair_pending_status[tenant_key]" (all tenants when omitted)'
    task :repair_pending_status, [:tenant_key] => :environment do |_t, args|
      dry_run = ActiveModel::Type::Boolean.new.cast(ENV.fetch('DRY_RUN', 'false'))
      accounts = args[:tenant_key].present? ? Account.where(tenant: args[:tenant_key]) : Account.all

      accounts.find_each do |account|
        Apartment::Tenant.switch(account.tenant) do
          Bulkrax::Importer.where(status_message: 'Pending').find_each do |importer|
            run = importer.last_run
            next if run.nil? || importer.validate_only

            latest = importer.latest_entry_statuses(run)
            label = "#{account.cname} importer #{importer.id} (#{importer.name}) run #{run.id}"
            if latest['Pending'].to_i.positive?
              puts "#{label}: #{latest['Pending']} entries still Pending, left alone"
              next
            end

            if dry_run
              puts "#{label}: would record status (entries #{latest.inspect}, enqueued_records=#{run.enqueued_records})"
            else
              importer.record_status_for(run, assume_queued: true)
              puts "#{label}: now #{importer.reload.status_message}"
            end
          end
        end
      end
    end
  end
end
