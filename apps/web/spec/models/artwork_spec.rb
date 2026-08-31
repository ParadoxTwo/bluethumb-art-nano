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

  describe "#sold?" do
    it "returns true when status is sold" do
      artwork = build(:artwork, :sold)
      expect(artwork.sold?).to be(true)
      expect(artwork.available?).to be(false)
    end
  end
end
