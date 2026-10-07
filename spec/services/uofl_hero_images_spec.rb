# frozen_string_literal: true

# UOFL OVERRIDE NEW FILE: Cover the hero image's random-per-visit rotation.
require 'rails_helper'

RSpec.describe UoflHeroImages do
  let(:images) do
    [
      { image: 'hero/a.webp', image_alt: 'A' },
      { image: 'hero/b.webp', image_alt: 'B' },
      { image: 'hero/c.webp', image_alt: 'C' }
    ]
  end
  let(:config) { { rotation_mode: 'random', images: } }
  let(:now) { Time.zone.parse('2026-10-07 12:00:00') }

  before { allow(described_class).to receive(:config).and_return(config) }

  around { |example| travel_to(now) { example.run } }

  describe '.visit_timeout_minutes' do
    it 'defaults to 30 when unset' do
      expect(described_class.visit_timeout_minutes).to eq(30)
    end

    it 'uses the configured value, including 0' do
      config[:visit_timeout_minutes] = 0
      expect(described_class.visit_timeout_minutes).to eq(0)
    end

    it 'falls back to the default for invalid values' do
      config[:visit_timeout_minutes] = 'soon'
      expect(described_class.visit_timeout_minutes).to eq(30)

      config[:visit_timeout_minutes] = -5
      expect(described_class.visit_timeout_minutes).to eq(30)
    end
  end

  describe '.current in random mode' do
    it 'keeps the remembered image within the same visit' do
      picture = described_class.current(remembered_image: 'hero/b.webp', remembered_at: (now - 29.minutes).to_i)
      expect(picture[:image]).to eq('hero/b.webp')
    end

    it 'picks a different image once the visit has timed out' do
      20.times do
        picture = described_class.current(remembered_image: 'hero/b.webp', remembered_at: (now - 30.minutes).to_i)
        expect(picture[:image]).not_to eq('hero/b.webp')
      end
    end

    it 'treats a remembered image with no timestamp as a new visit' do
      20.times do
        picture = described_class.current(remembered_image: 'hero/b.webp')
        expect(picture[:image]).not_to eq('hero/b.webp')
      end
    end

    it 'picks a new image on every load when the timeout is 0' do
      config[:visit_timeout_minutes] = 0
      picture = described_class.current(remembered_image: 'hero/b.webp', remembered_at: now.to_i)
      expect(picture[:image]).not_to eq('hero/b.webp')
    end

    it 'picks fresh when the remembered image was removed from the config' do
      picture = described_class.current(remembered_image: 'hero/gone.webp', remembered_at: now.to_i)
      expect(images.pluck(:image)).to include(picture[:image])
    end

    it 'can repeat the image when it is the only one configured' do
      config[:images] = [images.first]
      picture = described_class.current(remembered_image: 'hero/a.webp', remembered_at: (now - 1.hour).to_i)
      expect(picture[:image]).to eq('hero/a.webp')
    end

    it 'lets an active override win regardless of the visit' do
      config[:overrides] = [{ image: 'hero/override.webp', image_alt: 'Override' }]
      picture = described_class.current(remembered_image: 'hero/b.webp', remembered_at: now.to_i)
      expect(picture[:image]).to eq('hero/override.webp')
    end
  end

  describe '.current in weekly mode' do
    it 'ignores the remembered image and visit entirely' do
      config[:rotation_mode] = 'weekly'
      picture = described_class.current(remembered_image: 'hero/b.webp', remembered_at: now.to_i)
      expect(picture).to eq(described_class.rotated_image)
    end
  end
end
