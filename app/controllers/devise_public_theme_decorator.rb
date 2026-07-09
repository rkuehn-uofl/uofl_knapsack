# frozen_string_literal: true

# UOFL OVERRIDE: Devise's sign in/out, registration, password, and
# confirmation controllers are public-facing but aren't wired up like
# CatalogController/WorksHomeThemeDecorator (see catalog_controller_decorator.rb),
# so they never prepend the tenant's home theme view path. That means
# `render '/masthead'` on /users/sign_in, /users/sign_out, etc. resolves to
# the generic Hyrax masthead instead of the themed one.
[
  Devise::SessionsController,
  Devise::PasswordsController,
  Devise::ConfirmationsController,
  Devise::UnlocksController,
  Hyku::RegistrationsController
].each do |controller|
  controller.include(Hyku::HomePageThemesBehavior) unless controller < Hyku::HomePageThemesBehavior
end
