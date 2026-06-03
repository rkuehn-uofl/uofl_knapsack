# frozen_string_literal: true

# UOFL OVERRIDE: Add Turnstile verification route for public-page protection.
HykuKnapsack::Engine.routes.draw do
  post 'turnstile/verify', to: '/turnstile#verify', as: :turnstile_verify
end
