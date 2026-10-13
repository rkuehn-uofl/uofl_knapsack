# frozen_string_literal: true

# UOFL OVERRIDE NEW FILE: Cover the Item-number default redirect added to Bulkrax imports.
require 'logger'
require 'active_support/core_ext/array/wrap'
require 'active_support/core_ext/enumerable'
require 'active_support/core_ext/hash/keys'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/object/try'
require 'active_support/core_ext/string/inflections'

# Stand in for the real gems so this spec can run standalone, without booting
# Rails. When the full suite runs, rails_helper boots the real ones first, so
# skip each stub rather than reopening and overwriting real methods.
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

unless defined?(Hyrax)
  module Hyrax
    Config = Struct.new(:redirects_active?, :reserved_redirect_prefixes)

    def self.config
      @config ||= Config.new(false, %w[/concern /catalog])
    end

    class RedirectsLookup
      def self.taken?(*)
        false
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

require_relative '../../../app/factories/bulkrax/bulkrax_default_redirect_decorator'

module DefaultRedirectDecoratorSpec
  class ImageResource; end
  class CollectionResource; end
end
DefaultRedirectDecoratorSpecResource = Struct.new(:id, :redirects, keyword_init: true)

RSpec.describe Bulkrax::BulkraxDefaultRedirectDecorator do
  subject(:factory) { factory_class.new(base_attrs:, klass:, object:, attributes:) }

  let(:factory_class) do
    Class.new do
      prepend Bulkrax::BulkraxDefaultRedirectDecorator

      attr_reader :klass, :object, :attributes

      def initialize(base_attrs:, klass:, object:, attributes: {})
        @base_attrs = base_attrs
        @klass = klass
        @object = object
        @attributes = attributes
      end

      def transform_attributes(*)
        @base_attrs.dup
      end

      def permitted_attributes
        %i[title source_identifier redirects]
      end

      def source_identifier_value
        'ULPA 1981_008_004'
      end
    end
  end

  let(:base_attrs) { { title: ['A work'], source_identifier: 'ULPA 1981_008_004' } }
  let(:klass) { DefaultRedirectDecoratorSpec::ImageResource }
  let(:object) { nil }
  # The factory's parsed import attributes, before they're sliced to the
  # model's properties.
  let(:attributes) { { 'source_identifier' => 'ULPA 1981_008_004', 'collection_code' => 'ULPA' } }
  let(:field_mappings) { {} }
  let(:env_keys) do
    %w[
      BULKRAX_DEFAULT_REDIRECT_ENABLED
      BULKRAX_DEFAULT_REDIRECT_IS_DISPLAY_URL
      BULKRAX_DEFAULT_REDIRECT_PATH
      BULKRAX_DEFAULT_REDIRECT_COLLECTION_PATH
    ]
  end
  let(:redirects) { factory.transform_attributes[:redirects_attributes] }

  around do |example|
    original_env = env_keys.index_with { |key| ENV.fetch(key, nil) }
    env_keys.each { |key| ENV.delete(key) }

    example.run
  ensure
    original_env.each do |key, value|
      value.nil? ? ENV.delete(key) : ENV[key] = value
    end
  end

  before do
    ENV['BULKRAX_DEFAULT_REDIRECT_ENABLED'] = 'true'
    allow(Hyrax.config).to receive(:redirects_active?).and_return(true)
    allow(Hyrax.config).to receive(:reserved_redirect_prefixes).and_return(%w[/concern /catalog])
    allow(Hyrax::RedirectsLookup).to receive(:taken?).and_return(false)
    allow(Bulkrax).to receive(:field_mappings).and_return(field_mappings)
  end

  it 'adds the Item number alias when the row has no redirect columns' do
    expect(redirects).to eq(
      '0' => { 'path' => '/ulpa_1981_008_004', 'is_display_url' => 'false', '_destroy' => 'false' }
    )
  end

  it 'marks the alias as the display URL when configured' do
    ENV['BULKRAX_DEFAULT_REDIRECT_IS_DISPLAY_URL'] = 'true'

    expect(redirects['0']['is_display_url']).to eq('true')
  end

  it 'falls back to the Bulkrax source identifier' do
    base_attrs.delete(:source_identifier)
    attributes.delete('source_identifier')

    expect(redirects['0']['path']).to eq('/ulpa_1981_008_004')
  end

  it 'drops characters a redirect path cannot contain' do
    base_attrs[:source_identifier] = ['ULPA  CS#073/628 (a)']

    expect(redirects['0']['path']).to eq('/ulpa_cs073628_a')
  end

  it 'does nothing unless enabled' do
    ENV.delete('BULKRAX_DEFAULT_REDIRECT_ENABLED')

    expect(factory.transform_attributes).to eq(base_attrs)
  end

  it 'does nothing when the redirects feature is off' do
    allow(Hyrax.config).to receive(:redirects_active?).and_return(false)

    expect(factory.transform_attributes).to eq(base_attrs)
  end

  it 'does nothing on a Hyrax without the redirects feature' do
    allow(Hyrax).to receive(:config).and_return(Object.new)

    expect(factory.transform_attributes).to eq(base_attrs)
  end

  it 'does nothing for file sets' do
    redirects = factory_class.new(base_attrs:, klass: Bulkrax.file_model_class, object:, attributes:).transform_attributes
    expect(redirects).to eq(base_attrs)
  end

  context 'when importing a collection' do
    let(:klass) { Bulkrax.collection_model_class }
    let(:attributes) { { 'source_identifier' => 'ULPA 1981_008' } }

    before { base_attrs[:source_identifier] = 'ULPA 1981_008' }

    it 'adds the alias from the main template' do
      expect(redirects['0']['path']).to eq('/ulpa_1981_008')
    end

    it 'uses the collection template when set' do
      ENV['BULKRAX_DEFAULT_REDIRECT_PATH'] = '/{model}/{source_identifier}'
      ENV['BULKRAX_DEFAULT_REDIRECT_COLLECTION_PATH'] = '/finding-aids/{source_identifier}'

      expect(redirects['0']['path']).to eq('/finding-aids/ulpa_1981_008')
    end

    it 'fills {model} with collection' do
      allow(Bulkrax).to receive(:collection_model_class).and_return(DefaultRedirectDecoratorSpec::CollectionResource)
      ENV['BULKRAX_DEFAULT_REDIRECT_PATH'] = '/{model}/{source_identifier}'

      expect(redirects['0']['path']).to eq('/collection/ulpa_1981_008')
    end
  end

  it 'ignores the collection template for works' do
    ENV['BULKRAX_DEFAULT_REDIRECT_COLLECTION_PATH'] = '/finding-aids/{source_identifier}'

    expect(redirects['0']['path']).to eq('/ulpa_1981_008_004')
  end

  it 'keeps the CSV redirect columns instead of adding the default' do
    base_attrs[:redirects_attributes] = { '0' => { 'path' => '/handle/1/2', 'is_display_url' => 'false', '_destroy' => 'false' } }

    expect(factory.transform_attributes).to eq(base_attrs)
  end

  it 'adds the default when the CSV redirect columns are blank' do
    base_attrs[:redirects_attributes] = { '0' => { 'path' => '', '_destroy' => 'false' } }

    expect(redirects).to eq(
      '0' => { 'path' => '/ulpa_1981_008_004', 'is_display_url' => 'false', '_destroy' => 'false' }
    )
  end

  context 'when re-importing a work that already has aliases' do
    let(:object) do
      DefaultRedirectDecoratorSpecResource.new(id: 'abc', redirects: [{ path: '/legacy/123', is_display_url: true }])
    end

    it 'keeps the existing aliases and adds the default without a second display URL' do
      ENV['BULKRAX_DEFAULT_REDIRECT_IS_DISPLAY_URL'] = 'true'

      expect(redirects).to eq(
        '0' => { 'path' => '/legacy/123', 'is_display_url' => 'true', '_destroy' => 'false' },
        '1' => { 'path' => '/ulpa_1981_008_004', 'is_display_url' => 'false', '_destroy' => 'false' }
      )
    end

    it 'leaves the aliases alone when the default is already there' do
      object.redirects << { 'path' => '/ulpa_1981_008_004', 'is_display_url' => false }

      expect(factory.transform_attributes).to eq(base_attrs)
    end

    it 'excludes the work itself from the taken check' do
      factory.transform_attributes

      expect(Hyrax::RedirectsLookup).to have_received(:taken?).with('/ulpa_1981_008_004', except_id: 'abc')
    end
  end

  it 'skips the default when another record already uses the path' do
    allow(Hyrax::RedirectsLookup).to receive(:taken?).and_return(true)

    expect(factory.transform_attributes).to eq(base_attrs)
  end

  it 'skips the default when the path is reserved' do
    base_attrs[:source_identifier] = 'Catalog'

    expect(factory.transform_attributes).to eq(base_attrs)
  end

  describe 'BULKRAX_DEFAULT_REDIRECT_PATH' do
    it 'supports a literal prefix' do
      ENV['BULKRAX_DEFAULT_REDIRECT_PATH'] = '/image/{source_identifier}'

      expect(redirects['0']['path']).to eq('/image/ulpa_1981_008_004')
    end

    it 'fills {model} with the work type' do
      ENV['BULKRAX_DEFAULT_REDIRECT_PATH'] = '/{model}/{source_identifier}'

      expect(redirects['0']['path']).to eq('/image/ulpa_1981_008_004')
    end

    it 'drops the Resource suffix from multi-word work types' do
      stub_const('GenericWorkResource', Class.new)
      ENV['BULKRAX_DEFAULT_REDIRECT_PATH'] = '/{model}/{source_identifier}'

      redirects = factory_class.new(base_attrs:, klass: GenericWorkResource, object:, attributes:)
                               .transform_attributes[:redirects_attributes]
      expect(redirects['0']['path']).to eq('/generic_work/ulpa_1981_008_004')
    end

    it 'reads other import fields' do
      ENV['BULKRAX_DEFAULT_REDIRECT_PATH'] = '/{collection_code}/{source_identifier}'

      expect(redirects['0']['path']).to eq('/ulpa/ulpa_1981_008_004')
    end

    context 'when the CSV column is mapped to a differently named property' do
      let(:attributes) { { 'source_identifier' => 'ULPA 1981_008_004', 'publisher' => ['Photographic Archives'] } }
      let(:field_mappings) { { 'Bulkrax::CsvParser' => { 'publisher' => { 'from' => ['repository'] } } } }

      it 'reads the mapped property' do
        ENV['BULKRAX_DEFAULT_REDIRECT_PATH'] = '/{repository}/{source_identifier}'

        expect(redirects['0']['path']).to eq('/photographic_archives/ulpa_1981_008_004')
      end
    end

    it 'skips the alias when a placeholder has no value' do
      ENV['BULKRAX_DEFAULT_REDIRECT_PATH'] = '/{series}/{source_identifier}'

      expect(factory.transform_attributes).to eq(base_attrs)
    end

    it 'uses the default template when blank' do
      ENV['BULKRAX_DEFAULT_REDIRECT_PATH'] = '  '

      expect(redirects['0']['path']).to eq('/ulpa_1981_008_004')
    end

    it 'tolerates stray slashes' do
      ENV['BULKRAX_DEFAULT_REDIRECT_PATH'] = 'image//{source_identifier}/'

      expect(redirects['0']['path']).to eq('/image/ulpa_1981_008_004')
    end
  end
end
