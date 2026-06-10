# frozen_string_literal: true

# UOFL OVERRIDE NEW FILE: Cover Turnstile public-page matching rules.
require 'rails_helper'

RSpec.describe TurnstileProtectedPublicPage, type: :controller do
  controller(ApplicationController) do
    include TurnstileProtectedPublicPage

    def index
      head :ok
    end
  end

  before do
    routes.draw { get 'index' => 'anonymous#index' }

    allow(controller).to receive(:turnstile_active?).and_return(true)
    allow(controller).to receive(:turnstile_exempt_signed_in_user?).and_return(false)
    allow(controller).to receive(:turnstile_verified_for_host?).and_return(false)
    allow(controller).to receive(:admin_host?).and_return(false)
    allow(controller).to receive(:devise_controller?).and_return(false)
  end

  it 'matches catalog routes as public' do
    request.env['PATH_INFO'] = '/catalog'

    expect(controller.send(:turnstile_protected_public_request?)).to be(true)
  end

  it 'matches search history as public' do
    request.env['PATH_INFO'] = '/search_history'

    expect(controller.send(:turnstile_protected_public_request?)).to be(true)
  end

  it 'does not match direct download urls as public pages' do
    request.env['PATH_INFO'] = '/downloads/example-file-set'

    expect(controller.send(:turnstile_protected_public_request?)).to be(false)
  end

  it 'does not match riiif image urls as public pages' do
    request.env['PATH_INFO'] = '/images/example-file-set/full/600,/0/default.jpg'

    expect(controller.send(:turnstile_protected_public_request?)).to be(false)
  end

  it 'does not match pdf.js viewer assets as public pages' do
    request.env['PATH_INFO'] = '/pdf.js/viewer.html'

    expect(controller.send(:turnstile_protected_public_request?)).to be(false)
  end

  it 'does not match universal viewer assets as public pages' do
    request.env['PATH_INFO'] = '/uv/uv.html'

    expect(controller.send(:turnstile_protected_public_request?)).to be(false)
  end

  it 'does not match work manifest urls as public pages' do
    request.env['PATH_INFO'] = '/concern/images/example-work/manifest'

    expect(controller.send(:turnstile_protected_public_request?)).to be(false)
  end

  it 'matches oai endpoints as public' do
    request.env['PATH_INFO'] = '/catalog/oai'

    expect(controller.send(:turnstile_protected_public_request?)).to be(true)
  end

  it 'matches machine-readable catalog endpoints as public' do
    request.env['PATH_INFO'] = '/catalog/example-id/raw'

    expect(controller.send(:turnstile_protected_public_request?)).to be(true)
  end

  it 'does not match devise sign in routes as public' do
    request.env['PATH_INFO'] = '/users/sign_in'

    expect(controller.send(:turnstile_protected_public_request?)).to be(false)
  end

  it 'does not match devise sign out routes as public' do
    request.env['PATH_INFO'] = '/users/sign_out'

    expect(controller.send(:turnstile_protected_public_request?)).to be(false)
  end
end
