# frozen_string_literal: true

# UOFL OVERRIDE NEW FILE: Cover env-driven Bulkrax FileSet alt text generation.
require 'active_support/core_ext/array/wrap'
require 'active_support/core_ext/enumerable'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/object/try'

# Stand in for the real Bulkrax gem so this spec can run standalone, without
# booting Rails. When the full suite runs, rails_helper (required by other
# spec files) boots Rails - and with it the real Bulkrax gem - before this
# file loads, so skip the stub entirely rather than reopening the real
# Bulkrax module: redefining its field_mappings/collection_model_class/
# file_model_class here would silently and permanently overwrite those
# real, load-bearing methods for every other spec in the same process.
unless defined?(Bulkrax)
  module Bulkrax
    def self.field_mappings
      {}
    end

    def self.collection_model_class
      CollectionResource
    end

    def self.file_model_class
      FileSetResource
    end

    class CollectionResource; end
    class FileSetResource; end
    class ValkyrieObjectFactory; end
  end
end

require_relative '../../../app/factories/bulkrax/bulkrax_file_set_alt_text_decorator'

FileSetAltTextDecoratorSpecFileSet = Struct.new(:title, :alt_text, :original_filename, keyword_init: true)

RSpec.describe Bulkrax::BulkraxFileSetAltTextDecorator do
  subject(:factory) { factory_class.new(attributes:, base_params:, resource:, file_sets:) }

  let(:factory_class) do
    Class.new do
      prepend Bulkrax::BulkraxFileSetAltTextDecorator

      attr_reader :attributes, :user

      class << self
        attr_accessor :file_sets, :indexed_resources, :saved_resources

        def file_sets_for(*)
          file_sets
        end

        def filename_for(fileset:)
          fileset.try(:original_filename)
        end

        def save!(resource:, user:)
          saved_resources << [resource, user]
          resource
        end

        def update_index(resources:)
          indexed_resources.concat(resources)
        end
      end

      def initialize(attributes:, base_params:, resource: nil, file_sets: [])
        @attributes = attributes
        @base_params = base_params
        @resource = resource
        @user = Object.new
        self.class.file_sets = file_sets
        self.class.indexed_resources = []
        self.class.saved_resources = []
      end

      def file_set_params_for(*)
        @base_params
      end

      def run!
        @resource
      end
    end
  end

  let(:attributes) do
    { 'resource_type' => ['Still Image'], 'source_identifier' => ['RHINO_001'] }
  end
  let(:base_params) { [{}] }
  let(:files) { ['rhino1.jpg'] }
  let(:uploads) { [nil] }
  let(:resource) { nil }
  let(:file_sets) { [] }
  let(:env_keys) do
    %w[
      BULKRAX_FILESET_ALT_TEXT_ENABLED
      BULKRAX_FILESET_ALT_TEXT_FIELDS
      BULKRAX_FILESET_ALT_TEXT_SEPARATOR
      BULKRAX_FILESET_ALT_TEXT_SUFFIX
    ]
  end

  around do |example|
    original_env = env_keys.index_with { |key| ENV.fetch(key, nil) }
    env_keys.each { |key| ENV.delete(key) }

    example.run
  ensure
    original_env.each do |key, value|
      value.nil? ? ENV.delete(key) : ENV[key] = value
    end
  end

  describe '#file_set_params_for' do
    it 'bypasses generated alt text by default' do
      expect(file_set_params).to eq(base_params)
    end

    it 'generates FileSet alt text when enabled' do
      ENV['BULKRAX_FILESET_ALT_TEXT_ENABLED'] = 'true'

      expect(file_set_params).to eq(
        [
          {
            alt_text: ['rhino1.jpg']
          }
        ]
      )
    end

    it 'supports institution-specific field, separator, and suffix settings' do
      ENV['BULKRAX_FILESET_ALT_TEXT_ENABLED'] = 'true'
      ENV['BULKRAX_FILESET_ALT_TEXT_FIELDS'] = 'source_identifier,file_name'
      ENV['BULKRAX_FILESET_ALT_TEXT_SEPARATOR'] = ': '
      ENV['BULKRAX_FILESET_ALT_TEXT_SUFFIX'] = 'Image description follows.'

      expect(file_set_params.first[:alt_text]).to eq(
        ['RHINO_001: rhino1.jpg: Image description follows.']
      )
    end

    it 'joins suffix with the configured separator' do
      ENV['BULKRAX_FILESET_ALT_TEXT_ENABLED'] = 'true'
      ENV['BULKRAX_FILESET_ALT_TEXT_FIELDS'] = 'resource_type,file_name_without_extension'
      ENV['BULKRAX_FILESET_ALT_TEXT_SEPARATOR'] = '@@##!!'
      ENV['BULKRAX_FILESET_ALT_TEXT_SUFFIX'] = 'BLAH'

      expect(file_set_params.first[:alt_text]).to eq(['Still Image@@##!!rhino1@@##!!BLAH'])
    end

    it 'supports filename without extension when configured' do
      ENV['BULKRAX_FILESET_ALT_TEXT_ENABLED'] = 'true'
      ENV['BULKRAX_FILESET_ALT_TEXT_FIELDS'] = 'resource_type,file_name_without_extension'

      expect(file_set_params.first[:alt_text]).to eq(['Still Image rhino1'])
    end

    it 'does not overwrite existing alt text' do
      ENV['BULKRAX_FILESET_ALT_TEXT_ENABLED'] = 'true'
      base_params.first[:alt_text] = ['Alt text from import mapping']

      expect(file_set_params).to eq(base_params)
    end

    it 'does not overwrite existing alt text from string-keyed params' do
      ENV['BULKRAX_FILESET_ALT_TEXT_ENABLED'] = 'true'
      base_params.first['alt_text'] = ['Alt text from import mapping']

      expect(file_set_params).to eq(base_params)
    end

    %w[true TRUE 1 yes on].each do |enabled_value|
      it "generates FileSet alt text when enabled is #{enabled_value.inspect}" do
        ENV['BULKRAX_FILESET_ALT_TEXT_ENABLED'] = enabled_value

        expect(file_set_params.first[:alt_text]).to eq(
          ['rhino1.jpg']
        )
      end
    end
  end

  describe '#run!' do
    let(:resource) { Object.new }
    let(:file_sets) do
      [
        FileSetAltTextDecoratorSpecFileSet.new(title: ['rhino1.jpg'], alt_text: ['Old alt text'])
      ]
    end
    let(:attributes) do
      {
        'resource_type' => ['Still Image'],
        'file' => ['tmp/imports/hyku-dev/files/rhino1.jpg']
      }
    end

    it 'does not update persisted FileSet alt text by default' do
      factory.run!

      expect(file_sets.first.alt_text).to eq(['Old alt text'])
      expect(factory_class.saved_resources).to be_empty
      expect(factory_class.indexed_resources).to be_empty
    end

    it 'updates persisted FileSet alt text from the configured formula' do
      ENV['BULKRAX_FILESET_ALT_TEXT_ENABLED'] = 'true'
      ENV['BULKRAX_FILESET_ALT_TEXT_FIELDS'] = 'resource_type,file_name_without_extension'
      ENV['BULKRAX_FILESET_ALT_TEXT_SEPARATOR'] = ' '
      ENV['BULKRAX_FILESET_ALT_TEXT_SUFFIX'] = 'Detailed description follows.'

      factory.run!

      expect(file_sets.first.alt_text).to eq(['Still Image rhino1 Detailed description follows.'])
      expect(factory_class.saved_resources.map(&:first)).to eq(file_sets)
      expect(factory_class.indexed_resources).to eq([resource])
    end

    it 'falls back to the existing FileSet filename when the parsed file list is unavailable' do
      ENV['BULKRAX_FILESET_ALT_TEXT_ENABLED'] = 'true'
      ENV['BULKRAX_FILESET_ALT_TEXT_FIELDS'] = 'file_name_without_extension'
      ENV['BULKRAX_FILESET_ALT_TEXT_SUFFIX'] = 'Detailed description follows.'
      attributes.delete('file')

      factory.run!

      expect(file_sets.first.alt_text).to eq(['rhino1 Detailed description follows.'])
    end
  end

  def file_set_params
    factory.send(:file_set_params_for, uploads:, files:)
  end
end
