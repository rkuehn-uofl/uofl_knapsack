# frozen_string_literal: true

# UOFL OVERRIDE: Hyrax's own lib/hyrax/specs/shared_specs/simple_work.rb (required
# unconditionally by hyrax-webapp's generated spec/rails_helper.rb, for factory
# support) guards its Wings::ModelRegistry.register call with `if defined?(Wings)`.
# Under Zeitwerk, `Wings` (the bare top-level namespace) autoloads as a resolvable
# constant - backed by the Hyrax gem's own lib/wings directory - even when
# HYRAX_SKIP_WINGS=true causes Hyrax::Engine to skip the actual `require 'wings'`
# call. That makes `defined?(Wings)` true while `Wings::ModelRegistry` itself was
# never required, raising `NameError: uninitialized constant Wings::ModelRegistry`
# the moment any spec run boots - in every environment, not just test, and before
# a single example runs.
#
# Other Hyrax code (e.g. Hyrax::ResourceName) guards the same situation correctly
# with `defined?(Wings::ModelRegistry)` (the fully-qualified nested constant),
# which - unlike the bare `Wings` check - genuinely evaluates false when Wings was
# never required, so those call sites safely no-op today. Defining a real (if
# inert) `Wings::ModelRegistry` here would flip that check to true for every
# caller, not just simple_work.rb's, so this stub implements the full public
# interface as safe no-ops/nil-returns rather than just the one method
# simple_work.rb happens to call - anything that then asks the registry to look
# up a legacy ActiveFedora mapping correctly finds none, exactly as if Wings
# were absent, instead of hitting a NoMethodError on a half-built stub.
#
# Fixes this without editing the hyrax-webapp submodule or the vendored Hyrax gem.
#
# Scoped to the test environment only: simple_work.rb is loaded exclusively via
# spec/rails_helper.rb, so this stub is never needed in development/production. Defining
# it there anyway made `defined?(Wings::ModelRegistry)` true app-wide, which broke
# Hyrax::Collections::PermissionsService.filter_source (used by every admin_set/collection
# deposit-target lookup, including Bulkrax's importer picker) - it calls
# Wings::ModelRegistry.reverse_lookup, gets nil from this no-op stub, and drops every
# resource from the result. Outside test, Wings genuinely isn't loaded, so
# defined?(Wings::ModelRegistry) should - and without this stub, does - evaluate false,
# letting that code skip the (Wings-only) translation branch entirely.
if Hyrax.config.disable_wings && Rails.env.test?
  module Wings
    module ModelRegistry
      def self.register(*); end
      def self.unregister(*); end
      def self.lookup(*); nil; end
      def self.reverse_lookup(*); nil; end
    end
  end
end
