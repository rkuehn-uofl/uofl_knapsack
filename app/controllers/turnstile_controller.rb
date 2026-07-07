# frozen_string_literal: true

# UOFL OVERRIDE NEW FILE: Verify Cloudflare Turnstile responses and resume public browsing.
class TurnstileController < ApplicationController
  def verify
    token = params[:cf_turnstile_response].to_s

    return redirect_after_turnstile unless turnstile_active?

    if token.blank?
      render_turnstile_challenge('Please complete the verification challenge.')
      return
    end

    if turnstile_verifier_for(token).valid?
      session[:turnstile_verified_hosts] = session[:turnstile_verified_hosts].to_h.merge(request.host => true)
      redirect_after_turnstile
    else
      render_turnstile_challenge('Verification failed. Please try again.')
    end
  end

  private

  def redirect_after_turnstile
    redirect_to(session.delete(:turnstile_return_to).presence || root_path)
  end

  def render_turnstile_challenge(message)
    flash.now[:alert] = message
    response.headers['Cache-Control'] = 'no-store'
    render 'turnstile/challenge', layout: false, status: :forbidden
  end

  def turnstile_verifier_for(token)
    TurnstileVerifier.new(secret_key: turnstile_secret_key, response_token: token, remote_ip: request.remote_ip)
  end
end
