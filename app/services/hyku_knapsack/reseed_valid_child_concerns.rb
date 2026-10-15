# frozen_string_literal: true

# UOFL OVERRIDE NEW FILE: copied from upstream hyku_knapsack (prime/main) ahead of the
# knapsack upgrade, with one change in #call (marked below).
module HykuKnapsack
  # Re-seed each work model's `valid_child_concerns` from the fully-registered
  # `Hyrax.config.curation_concerns`.
  #
  # Hyrax::NestedWorks snapshots `Hyrax.config.curation_concerns` into a class
  # attribute (`valid_child_concerns`) at class-load. A knapsack that registers
  # its work types in a deferred `after_initialize` block (e.g. because the
  # M3/flex constants aren't resolvable at initializer-evaluation time) hits an
  # ordering trap under eager loading: the work-type classes load BEFORE the
  # deferred registration runs, so the snapshot freezes to whatever concerns
  # were registered at boot (Hyku's defaults) and never picks up the knapsack's
  # types. The "Add child work" picker on the work show page then offers the
  # wrong types on eager-loaded environments (production/staging) while working
  # correctly in development (which lazy-loads classes after registration).
  #
  # This service, run after registration is complete, re-seeds every registered
  # work model from the final concern list so the class attribute is correct in
  # every environment. HykuKnapsack wires it via the engine `to_prepare` for the
  # dev-reload pass. A knapsack that DEFERS curation-concern registration to its
  # own after_initialize must also call `HykuKnapsack::ReseedValidChildConcerns
  # .call` at the end of that registration block for the eager-load boot pass —
  # the engine hooks all run before an initializer-file after_initialize.
  #
  # A work type can bar itself from ever being a child (of any parent, including
  # itself) by defining `self.valid_child_concern?` to return false. Such types
  # are excluded from every model's child list. Types that do not define the
  # method remain valid children by default.
  #
  # The mirror image is `self.valid_parent_concern?`: a type returning false
  # accepts no children at all, so its own list is emptied. Types that do not
  # define it remain valid parents by default.
  module ReseedValidChildConcerns
    module_function

    def call
      concerns = Hyrax.config.curation_concerns
      child_concerns = concerns.reject { |klass| barred_as_child?(klass) }
      # UOFL OVERRIDE: also re-seed the Valkyrie classes behind Hyku's lazy-migrated
      # types. Hyku registers GenericWork/Image/Etd/Oer, but their works are
      # GenericWorkResource/ImageResource/..., which is the class Hyrax::ChildTypes
      # (and Hyku's ensure_parent_accepts_child) reads. Without this, Text can't be
      # attached as a child of those works. The child list itself stays the
      # registered concerns, which is what the tenant's available_works filter matches.
      # Uses HykuApp.work_types rather than Hyrax::ModelRegistry.work_classes, which
      # memoizes and would freeze without Text if first called on the boot pass.
      (concerns + Array(Rails.application.class.try(:work_types))).uniq.each do |klass|
        next unless klass.respond_to?(:valid_child_concerns=)

        klass.valid_child_concerns = barred_as_parent?(klass) ? [] : child_concerns
      end
    end

    def barred_as_child?(klass)
      klass.respond_to?(:valid_child_concern?) && !klass.valid_child_concern?
    end

    # A type that declares itself not a valid parent accepts no children: its list
    # is emptied, so Hyrax::ChildTypes.for returns nothing and the show page's
    # "Attach child" control does not render. This gates the UI entry point only.
    # member_ids, importers, and already-nested data are untouched, so a type whose
    # valid_parent_concern? goes back to true regains the control with its existing
    # nesting intact.
    def barred_as_parent?(klass)
      klass.respond_to?(:valid_parent_concern?) && !klass.valid_parent_concern?
    end
  end
end
