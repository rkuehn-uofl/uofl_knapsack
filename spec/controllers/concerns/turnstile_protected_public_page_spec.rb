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

  it 'matches direct download urls as public' do
    request.env['PATH_INFO'] = '/downloads/example-file-set'

    expect(controller.send(:turnstile_protected_public_request?)).to be(true)
  end

  it 'matches oai endpoints as public' do
    request.env['PATH_INFO'] = '/catalog/oai'

    expect(controller.send(:turnstile_protected_public_request?)).to be(true)
  end

  it 'matches machine-readable catalog endpoints as public' do
    request.env['PATH_INFO'] = '/catalog/example-id/raw'

    expect(controller.send(:turnstile_protected_public_request?)).to be(true)
  end

  it 'does not match devise routes as public' do
    request.env['PATH_INFO'] = '/users/sign_in'

    expect(controller.send(:turnstile_protected_public_request?)).to be(false)
  end
end
