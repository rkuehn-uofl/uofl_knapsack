# frozen_string_literal: true

# UOFL OVERRIDE NEW FILE: Define public-page Turnstile gating and exemption rules.
module TurnstileProtectedPublicPage
  extend ActiveSupport::Concern

  TURNSTILE_EXEMPT_PATH_PREFIXES = %w[
    /account
    /admin
    /api
    /assets
    /authorities
    /bookmarks
    /browse
    /dashboard
    /jobs
    /notifications
    /proprietor
    /rails
    /site
    /single_signon
    /status
    /turnstile
    /uploads
    /users
    /v2
  ].freeze

  included do
    helper_method :turnstile_site_key
  end

  private

  def require_turnstile_for_public_page
    return unless turnstile_protected_public_request?
    return if turnstile_exempt_signed_in_user?
    return if turnstile_verified_for_host?

    session[:turnstile_return_to] = request.fullpath
    response.headers['Cache-Control'] = 'no-store'
    render 'turnstile/challenge', layout: false
  end

  def turnstile_protected_public_request?
    return false unless turnstile_active?
    return false unless request.get? || request.head?
    return false if turnstile_exempt_request?
    return false if request.path.blank?

    true
  end

  def turnstile_active?
    return false if turnstile_bypass?

    turnstile_enabled? && turnstile_site_key.present? && turnstile_secret_key.present?
  end

  def turnstile_bypass?
    Rails.configuration.x.turnstile.bypass
  end

  def turnstile_enabled?
    Rails.configuration.x.turnstile.enabled
  end

  def turnstile_site_key
    Rails.configuration.x.turnstile.site_key
  end

  def turnstile_secret_key
    Rails.configuration.x.turnstile.secret_key
  end

  def turnstile_verified_for_host?
    verified_hosts = session[:turnstile_verified_hosts]
    verified_hosts.is_a?(Hash) && verified_hosts[request.host] == true
  end

  def turnstile_exempt_request?
    return true if admin_host?
    return true if devise_controller?
    return true if turnstile_exempt_path?

    false
  end

  def turnstile_exempt_path?
    TURNSTILE_EXEMPT_PATH_PREFIXES.any? { |prefix| request.path.start_with?(prefix) }
  end

  def turnstile_exempt_signed_in_user?
    return false if current_user.blank?
    return false if current_user.respond_to?(:guest?) && current_user.guest?

    true
  end
end
