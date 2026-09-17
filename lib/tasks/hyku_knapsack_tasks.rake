# frozen_string_literal: true

namespace :hyku_knapsack do
  namespace :i18n do
    desc 'Translate missing locale keys from English to all other languages'
    task translate_missing: :environment do
      hyku_i18n_config_path = '/app/samvera/hyrax-webapp/config/i18n-tasks.yml'

      sh "cd /app/samvera && bundle exec i18n-tasks translate-missing --config #{hyku_i18n_config_path} --from en de es fr it pt-BR zh"
    end
  end

  namespace :m3 do
    desc 'Re-save every work/collection/admin-set for a tenant so its schema_version stamp and Solr index match the ' \
         'current M3 (Hyrax::FlexibleSchema) profile. Does NOT backfill values into newly added fields - those stay ' \
         'blank until someone edits and saves the record. This is a real write (bumps updated_at, fires ' \
         'object.metadata.updated/collection.metadata.updated events) for every matching resource, not a read-only ' \
         'reindex. Usage: rake "hyku_knapsack:m3:resave_all[tenant_key]"'
    task :resave_all, [:tenant_key] => :environment do |_t, args|
      tenant_key = args[:tenant_key]
      abort 'Usage: rake "hyku_knapsack:m3:resave_all[tenant_key]"' if tenant_key.blank?

      AccountElevator.switch!(tenant_key)
      current_schema_id = Hyrax::FlexibleSchema.current_schema_id
      puts "Re-saving tenant '#{tenant_key}' resources onto M3 schema v#{current_schema_id}..."

      total = 0
      updated = 0
      failed = 0

      Hyrax.query_service.find_all.each do |resource|
        next unless resource.is_a?(Hyrax::Resource)

        total += 1
        resource.schema_version = current_schema_id
        resource.save
        updated += 1
      rescue StandardError => e
        failed += 1
        Rails.logger.error("[hyku_knapsack:m3:resave_all] Update failed for #{resource.id}: #{e.message}")
        puts "  FAILED #{resource.id}: #{e.message}"
      end

      puts "Done: #{updated}/#{total} resources re-saved to schema v#{current_schema_id}, #{failed} failed."
    end
  end
end
