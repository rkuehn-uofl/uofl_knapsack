# frozen_string_literal: true

# UOFL OVERRIDE NEW FILE: Cover the UofL Text work indexer.
# Generated via
#  `rails generate hyrax:work_resource Text`
require 'rails_helper'
require 'hyrax/specs/shared_specs/indexers'

RSpec.describe TextIndexer do
  let(:indexer_class) { described_class }
  let!(:resource) { Hyrax.persister.save(resource: Text.new) }

  it_behaves_like 'a Hyrax::Resource indexer'
end
