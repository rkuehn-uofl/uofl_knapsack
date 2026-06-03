# frozen_string_literal: true

# UOFL OVERRIDE NEW FILE: Attach Cloudflare Turnstile protection to public page requests.
module ApplicationControllerDecorator
  def self.prepended(base)
    base.include TurnstileProtectedPublicPage
    base.prepend_before_action :require_turnstile_for_public_page
  end

  protected

  def after_sign_out_path_for(_resource_or_scope)
    new_user_session_path(locale: params[:locale].presence)
  end
end

ApplicationController.prepend(ApplicationControllerDecorator)
