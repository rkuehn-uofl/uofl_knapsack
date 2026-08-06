# frozen_string_literal: true

# UOFL OVERRIDE NEW FILE: Fix NoMethodError when Bulkrax reimports/deletes an
# existing work. Hyrax::CustomQueries#find_child_file_sets returns an
# Enumerator::Lazy in this app's Hyrax version, and Enumerator::Lazy has no
# #empty? method — upstream Bulkrax 9.3.5/9.5.1 calls #empty? directly and
# crashes before any files are actually deleted. Materializing the lazy
# enumerator with #to_a once, up front, fixes the crash and also avoids
# re-running the underlying Valkyrie query twice (once for the later
# `.each`, once for the later `.detect` inside `member_ids.reject`).
module Bulkrax
  module ValkyrieObjectFactoryDestroyFilesDecorator
    def destroy_existing_files(object: @object)
      existing_files = Hyrax.custom_queries.find_child_file_sets(resource: object).to_a
      return if existing_files.empty?

      existing_files.each do |fs|
        transactions["file_set.destroy"]
          .with_step_args("file_set.remove_from_work" => { user: @user },
                          "file_set.delete" => { user: @user })
          .call(fs)
          .value!
      end

      object.member_ids = object.member_ids.reject { |m| existing_files.detect { |f| f.id == m } }
      object.rendering_ids = []
      object.representative_id = nil
      object.thumbnail_id = nil
    end
  end
end

Bulkrax::ValkyrieObjectFactory.prepend(Bulkrax::ValkyrieObjectFactoryDestroyFilesDecorator)
