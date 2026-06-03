# frozen_string_literal: true

# UOFL OVERRIDE NEW FILE: Cover Turnstile verification redirects and failures.
require 'rails_helper'

RSpec.describe TurnstileController, type: :controller do
  routes { HykuKnapsack::Engine.routes }

  describe 'POST #verify' do
    let(:verifier) { instance_double(TurnstileVerifier) }

    before do
      request.host = 'tenant.example.test'
      session[:turnstile_return_to] = '/catalog'

      allow(controller).to receive(:turnstile_enabled?).and_return(true)
      allow(controller).to receive(:turnstile_site_key).and_return('site-key')
      allow(controller).to receive(:turnstile_secret_key).and_return('secret-key')
      allow(TurnstileVerifier).to receive(:new).and_return(verifier)
    end

    it 'marks the current host as verified and redirects back on success' do
      allow(verifier).to receive(:valid?).and_return(true)

      post :verify, params: { cf_turnstile_response: 'token-123' }

      expect(session[:turnstile_verified_hosts]).to include('tenant.example.test' => true)
      expect(response).to redirect_to('/catalog')
    end

    it 're-renders the challenge on failure' do
      allow(verifier).to receive(:valid?).and_return(false)

      post :verify, params: { cf_turnstile_response: 'token-123' }

      expect(response).to have_http_status(:forbidden)
      expect(response).to render_template('turnstile/challenge')
      expect(flash[:alert]).to eq('Verification failed. Please try again.')
    end
  end
end
