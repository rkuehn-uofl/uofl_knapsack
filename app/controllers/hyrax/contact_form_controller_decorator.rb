# frozen_string_literal: true

module HykuKnapsack
  module ContactFormControllerDecorator
    # UOFL OVERRIDE: Hyrax::Engine mounts before HykuKnapsack::Engine in
    # hyrax-webapp/config/routes.rb (a submodule we don't edit), so the
    # /contact route can't be overridden or removed from our own routes
    # file - it'd never be reached. hyrax-webapp also ships its own
    # Hyrax::ContactFormControllerDecorator (adds the captcha/theming) that
    # loads after this one and redefines #new/#create, so overriding those
    # methods here would just get shadowed. A before_action halts the
    # filter chain before either version of #new/#create runs, sidestepping
    # that load-order/method-resolution race entirely.
    def uofl_redirect_away_from_contact_form
      redirect_to main_app.root_path
    end
  end
end

Hyrax::ContactFormController.prepend(HykuKnapsack::ContactFormControllerDecorator)
Hyrax::ContactFormController.before_action(:uofl_redirect_away_from_contact_form, only: %i[new create])
