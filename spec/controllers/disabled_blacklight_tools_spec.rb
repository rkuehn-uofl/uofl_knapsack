# frozen_string_literal: true

# UOFL OVERRIDE NEW FILE: Cover the disabled bookmarks, search history, and
# catalog email/SMS endpoints.
require 'rails_helper'

RSpec.describe 'Disabled Blacklight tools', type: :controller do
  describe BookmarksController do
    routes { Rails.application.routes }

    it '404s the bookmarks index' do
      expect { get :index }.to raise_error(ActionController::RoutingError)
    end
  end

  describe SearchHistoryController do
    routes { Blacklight::Engine.routes }

    it '404s the search history page' do
      expect { get :index }.to raise_error(ActionController::RoutingError)
    end
  end

  describe CatalogController do
    routes { Rails.application.routes }

    it '404s the record email action' do
      expect { post :email, params: { id: 'abc123', to: 'someone@example.com' } }
        .to raise_error(ActionController::RoutingError)
    end

    it '404s the record SMS action' do
      expect { post :sms, params: { id: 'abc123', to: '5025551234', carrier: 'txt.att.net' } }
        .to raise_error(ActionController::RoutingError)
    end

    it 'removes the email/SMS buttons and bookmark/search history nav links' do
      config = CatalogController.blacklight_config
      expect(config.show.document_actions.keys).not_to include(:email, :sms)
      expect(config.navbar.partials.keys).not_to include(:bookmark, :search_history)
    end
  end
end
