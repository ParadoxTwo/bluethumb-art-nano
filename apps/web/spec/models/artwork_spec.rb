# frozen_string_literal: true

require "rails_helper"

RSpec.describe Artwork do
  describe "scopes" do
    let!(:abstract) { create(:artwork, style: "abstract") }
    let!(:landscape_style) { create(:artwork, style: "landscape", slug: "landscape-piece") }

    it "filters by style" do
      expect(described_class.by_style("abstract")).to contain_exactly(abstract)
    end

    it "filters by price range in cents" do
      cheap = create(:artwork, price_cents: 40_000, slug: "cheap-piece")
      create(:artwork, price_cents: 200_000, slug: "expensive-piece")

      expect(described_class.by_price_range(300..600)).to contain_exactly(cheap)
    end

    it "filters available artworks only" do
      sold = create(:artwork, :sold, slug: "sold-piece")
      expect(described_class.available).to contain_exactly(abstract, landscape_style)
      expect(described_class.available).not_to include(sold)
    end
  end

  describe "#available?" do
    it "returns true when status is available" do
      artwork = build(:artwork, status: "available")
      expect(artwork.available?).to be(true)
      expect(artwork.sold?).to be(false)
    end
  end

  describe "#palette_swatches" do
    it "returns normalised swatches from palette_data" do
      artwork = build(:artwork, :with_swatches)

      expect(artwork.palette_swatches).to eq(
        [
          { "hex" => "#3366cc", "population" => 0.5 },
          { "hex" => "#ddeeff", "population" => 0.3 }
        ]
      )
    end

    it "returns an empty array when no palette has been extracted" do
      expect(build(:artwork).palette_swatches).to eq([])
    end

    it "drops malformed swatches rather than rendering them" do
      artwork = build(:artwork, palette_data: {
                        "swatches" => [
                          { "hex" => "#3366CC", "population" => 0.4 },
                          { "hex" => "not-a-colour" },
                          { "population" => 0.1 },
                          "nonsense"
                        ]
                      })

      expect(artwork.palette_swatches).to eq([{ "hex" => "#3366cc", "population" => 0.4 }])
    end

    it "caps the number of swatches" do
      swatches = Array.new(10) { |i| { "hex" => format("#%06x", i), "population" => 0.1 } }
      artwork = build(:artwork, palette_data: { "swatches" => swatches })

      expect(artwork.palette_swatches.size).to eq(Artwork::MAX_SWATCHES)
    end
  end

  describe "#sold?" do
    it "returns true when status is sold" do
      artwork = build(:artwork, :sold)
      expect(artwork.sold?).to be(true)
      expect(artwork.available?).to be(false)
    end
  end
end
