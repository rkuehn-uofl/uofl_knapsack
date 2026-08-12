# frozen_string_literal: true

module HykuKnapsack
  module StaticControllerDecorator
    # UOFL OVERRIDE: Hyrax::Engine mounts before HykuKnapsack::Engine in
    # hyrax-webapp/config/routes.rb (a submodule we don't edit), so the
    # /zotero and /mendeley routes can't be overridden or removed from our
    # own routes file - they'd never be reached. Disabling the actions here
    # instead, regardless of route order.
    def zotero
      redirect_to main_app.root_path
    end

    def mendeley
      redirect_to main_app.root_path
    end
  end
end

Hyrax::StaticController.prepend(HykuKnapsack::StaticControllerDecorator)
