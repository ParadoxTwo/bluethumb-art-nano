# frozen_string_literal: true

require "spec_helper"

RSpec.describe PaletteExtractor do
  subject(:extractor) { described_class.new }

  describe "#extract_from_rgb" do
    it "returns the swatch hex for the colour it was given" do
      palette = extractor.extract_from_rgb(123, 178, 250)

      expect(palette[:swatches].first[:hex]).to eq("#7bb2fa")
    end

    # Regression: the blue channel and the CIELAB b* axis were both named b, so
    # the hex was formatted from b*. Ruby renders a negative integer in %x as
    # "..f<hex>", so this wrote plausible-looking rubbish such as "#7bb2..fb"
    # into palette_data instead of raising.
    it "does not let the CIELAB b* axis stand in for the blue channel" do
      palette = extractor.extract_from_rgb(123, 178, 250)

      expect(palette[:swatches].first[:hex]).to match(/\A#\h{6}\z/)
      expect(palette.dig(:centroid, :b)).to be < 0
      expect(palette[:swatches].first[:hex]).not_to include("..")
    end

    it "emits a valid hex for every corner of the RGB cube" do
      [[0, 0, 0], [255, 255, 255], [255, 0, 0], [0, 255, 0], [0, 0, 255],
       [12, 200, 7], [250, 250, 5]].each do |rgb|
        hex = extractor.extract_from_rgb(*rgb)[:swatches].first[:hex]

        expect(hex).to match(/\A#\h{6}\z/), "#{rgb.inspect} produced #{hex.inspect}"
      end
    end

    it "reports the LAB centroid alongside the swatch" do
      palette = extractor.extract_from_rgb(255, 255, 255)

      expect(palette.dig(:centroid, :l)).to be_within(0.5).of(100.0)
      expect(palette[:swatches].first[:lab][:l]).to be_within(0.5).of(100.0)
    end

    it "clamps and rounds out-of-range channels rather than emitting a non-colour" do
      hex = extractor.extract_from_rgb(-12, 300, 128.6)[:swatches].first[:hex]

      expect(hex).to eq("#00ff81")
    end

    it "names a hue family from the declared vocabulary" do
      family = extractor.extract_from_rgb(220, 30, 30)[:hue_family]

      expect(described_class::HUE_FAMILIES.values.uniq).to include(family)
    end

    # Documented defect, deliberately out of scope for this change.
    #
    # HUE_FAMILIES buckets an HSV-style hue wheel (red at 0, blue at 240), but
    # it is fed the CIELAB hue angle, where red sits near 40 degrees, yellow
    # near 100 and blue near 275. So pure red is filed as "orange", sky blue
    # and navy as "purple", and lemon as "green". Neutral grey is worse: its
    # chroma is ~0, the hue angle is meaningless, and it lands in "purple"
    # instead of "neutral".
    #
    # This drives Artwork.by_hue_family, which is a browse facet, so the whole
    # catalogue is mislabelled. Fixing it means choosing LAB ranges and adding
    # a chroma threshold for neutrals - a separate change with its own specs.
    it "files primary colours under the family a buyer would name" do
      pending "HUE_FAMILIES buckets HSV degrees but receives CIELAB hue angles"

      expect(extractor.extract_from_rgb(255, 0, 0)[:hue_family]).to eq("red")
      expect(extractor.extract_from_rgb(60, 140, 220)[:hue_family]).to eq("blue")
      expect(extractor.extract_from_rgb(128, 128, 128)[:hue_family]).to eq("neutral")
    end
  end
end
