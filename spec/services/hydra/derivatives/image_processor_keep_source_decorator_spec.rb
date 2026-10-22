# frozen_string_literal: true

# UOFL OVERRIDE NEW FILE: Cover the MiniMagick Tempfile/GC race in image derivatives.
require 'mini_magick'
require 'hydra/derivatives'
require 'tmpdir'

require_relative '../../../../app/services/hydra/derivatives/image_processor_keep_source_decorator'

# Forces a full GC just before MiniMagick runs mogrify on an image, which is
# the window where the stock processor no longer references the source image.
# Prepended modules cannot be removed, so it only acts while the flag is set.
module ImageProcessorKeepSourceDecoratorSpecForceGc
  class << self
    attr_accessor :enabled
  end

  private

  def mogrify(*)
    3.times { GC.start(full_mark: true, immediate_sweep: true) } if ImageProcessorKeepSourceDecoratorSpecForceGc.enabled
    super
  end
end
MiniMagick::Image.prepend(ImageProcessorKeepSourceDecoratorSpecForceGc)

RSpec.describe Hydra::Derivatives::ImageProcessorKeepSourceDecorator do
  let(:source) { File.join(Dir.mktmpdir, 'source.jpg') }
  let(:directives) { { label: :thumbnail, format: 'jpg', size: '600x450>', url: 'thumbnail', layer: 0 } }
  let(:output) do
    Class.new do
      attr_reader :bytes

      def call(io, _directives)
        @bytes = io.read
      end
    end.new
  end

  before do
    MiniMagick::Tool::Magick.new do |magick|
      magick.size '800x600'
      magick << 'gradient:white-black'
      magick << source
    end
    ImageProcessorKeepSourceDecoratorSpecForceGc.enabled = true
  end

  after do
    ImageProcessorKeepSourceDecoratorSpecForceGc.enabled = false
    FileUtils.rm_rf(File.dirname(source))
  end

  it 'is prepended to the hydra-derivatives image processor' do
    expect(Hydra::Derivatives::Processors::Image.ancestors).to include(described_class)
  end

  it 'still writes the thumbnail when GC runs after the switch to layer 0' do
    10.times do
      Hydra::Derivatives::Processors::Image.new(source, directives, output_file_service: output).process
    end

    image = MiniMagick::Image.read(output.bytes)
    expect(image.type).to eq('JPEG')
    expect([image.width, image.height]).to eq([600, 450])
  end
end
