# frozen_string_literal: true

# UOFL OVERRIDE NEW FILE: Cover the global Turnstile callback on public pages.
require 'rails_helper'

RSpec.describe 'Turnstile public page protection', type: :controller do
  render_views

  describe ApplicationController do
    it 'attaches the global callback through the application controller decorator' do
      filters = ApplicationController._process_action_callbacks.map(&:filter)
      expect(filters).to include(:require_turnstile_for_public_page)
    end
  end

  describe CatalogController, clean_repo: true do
    routes { Rails.application.routes }

    before do
      request.host = 'test.host'
      allow_any_instance_of(ApplicationController).to receive(:turnstile_enabled?).and_return(true)
      allow_any_instance_of(ApplicationController).to receive(:turnstile_site_key).and_return('site-key')
      allow_any_instance_of(ApplicationController).to receive(:turnstile_secret_key).and_return('secret-key')
    end

    it 'allows verified visitors through' do
      session[:turnstile_verified_hosts] = { 'test.host' => true }

      request.env['PATH_INFO'] = '/catalog'
      get :index, params: { q: 'history' }

      expect(response).to be_successful
      expect(response).not_to render_template('turnstile/challenge')
    end
  end
end
