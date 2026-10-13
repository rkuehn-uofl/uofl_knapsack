# frozen_string_literal: true

# UOFL OVERRIDE NEW FILE: Cover redirect alias cleanup when Bulkrax deletes a record.
require 'logger'
require 'dry/monads'
require 'active_support/core_ext/object/blank'

# Stand in for the real gems so this spec can run standalone, without booting
# Rails. When the full suite runs, rails_helper boots the real ones first, so
# skip each stub rather than reopening and overwriting real classes.
unless defined?(Bulkrax)
  module Bulkrax
    class ValkyrieObjectFactory; end
  end
end

unless defined?(Hyrax::Transactions::Steps::RemoveRedirectPaths)
  module Hyrax
    module Transactions
      module Steps
        class RemoveRedirectPaths
          def call(resource)
            Dry::Monads::Success(resource)
          end
        end
      end
    end
  end
end

unless defined?(Rails)
  module Rails
    def self.logger
      @logger ||= Logger.new(nil)
    end
  end
end

require_relative '../../../app/factories/bulkrax/valkyrie_object_factory_remove_redirects_decorator'

RemoveRedirectsDecoratorSpecResource = Struct.new(:id)

RSpec.describe Bulkrax::ValkyrieObjectFactoryRemoveRedirectsDecorator do
  subject(:factory) { factory_class.new(resource) }

  let(:factory_class) do
    Class.new do
      prepend Bulkrax::ValkyrieObjectFactoryRemoveRedirectsDecorator

      attr_reader :deleted

      def initialize(resource)
        @resource = resource
      end

      def find
        @resource
      end

      def delete(_user)
        raise 'Object not found to delete' unless @resource

        @deleted = true
        :deleted
      end
    end
  end

  let(:resource) { RemoveRedirectsDecoratorSpecResource.new('abc') }
  let(:step) { instance_double(Hyrax::Transactions::Steps::RemoveRedirectPaths) }

  before do
    allow(Hyrax::Transactions::Steps::RemoveRedirectPaths).to receive(:new).and_return(step)
    allow(step).to receive(:call) { |res| Dry::Monads::Success(res) }
  end

  it 'deletes the record, then removes its redirect aliases' do
    expect(factory.delete(nil)).to eq(:deleted)
    expect(factory.deleted).to be(true)
    expect(step).to have_received(:call).with(resource)
  end

  it 'still deletes when the alias cleanup fails' do
    allow(step).to receive(:call).and_return(Dry::Monads::Failure([:redirect_path_remove_error, 'boom']))

    expect(factory.delete(nil)).to eq(:deleted)
  end

  context 'when the record does not exist' do
    let(:resource) { nil }

    it 'raises the delete error without removing aliases' do
      expect { factory.delete(nil) }.to raise_error('Object not found to delete')
      expect(step).not_to have_received(:call)
    end
  end
end
