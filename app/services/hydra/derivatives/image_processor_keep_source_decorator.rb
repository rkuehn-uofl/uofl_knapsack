# frozen_string_literal: true

# UOFL OVERRIDE NEW FILE: Fix thumbnails randomly failing with
# "UnableToOpenBlob '/tmp/mini_magick....jpg': No such file or directory".
#
# Hydra::Derivatives::Processors::Image opens the source with
# MiniMagick::Image.open, which copies it to a Tempfile held only by that image
# object. Hyrax's image/pdf/office derivative directives set `layer: 0`, so
# #selected_layers swaps it for `image.layers[0]`, a new MiniMagick::Image for
# "<tempfile>[0]" that does not reference the Tempfile. Nothing keeps the
# original image alive after that, so if Ruby's GC runs before the resize, the
# Tempfile finalizer unlinks the file and ImageMagick fails. GC runs often
# during large Bulkrax imports, so the job can lose the race on every retry.
#
# Keeping a reference to the source image for the life of the processor keeps
# the Tempfile on disk until the derivative has been written.
module Hydra
  module Derivatives
    module ImageProcessorKeepSourceDecorator
      private

      def selected_layers(image)
        @source_image = image
        super
      end
    end
  end
end

Hydra::Derivatives::Processors::Image.prepend(Hydra::Derivatives::ImageProcessorKeepSourceDecorator)
