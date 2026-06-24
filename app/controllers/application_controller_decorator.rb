# frozen_string_literal: true

# UOFL OVERRIDE NEW FILE: Attach Cloudflare Turnstile protection to public page requests.
module ApplicationControllerDecorator
  def self.prepended(base)
    base.include TurnstileProtectedPublicPage
    base.prepend_before_action :require_turnstile_for_public_page
  end
end

ApplicationController.prepend(ApplicationControllerDecorator)
