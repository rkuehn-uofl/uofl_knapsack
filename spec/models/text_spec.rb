# frozen_string_literal: true

# UOFL OVERRIDE NEW FILE: Cover the UofL Text work type.
# Generated via
#  `rails generate hyrax:work_resource Text`
require 'rails_helper'
require 'hyrax/specs/shared_specs/hydra_works'

RSpec.describe Text do
  subject(:work) { described_class.new }

  it_behaves_like 'a Hyrax::Work'
end
