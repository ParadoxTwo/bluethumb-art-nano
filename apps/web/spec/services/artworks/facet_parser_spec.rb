# frozen_string_literal: true

require "rails_helper"

RSpec.describe Artworks::FacetParser do
  it "parses facet segments" do
    facets = described_class.parse(%w[style abstract price 500-1000])
    expect(facets).to eq("style" => "abstract", "price" => "500-1000")
  end

  it "raises on unknown facet keys" do
    expect { described_class.parse(%w[unknown value]) }.to raise_error(Artworks::FacetParser::InvalidFacetError)
  end

  describe ".price_range" do
    it "parses the 0-500 bucket" do
      expect(described_class.price_range("0-500")).to eq(0..500)
    end

    it "rejects equal min and max" do
      expect { described_class.price_range("500-500") }.to raise_error(Artworks::FacetParser::InvalidFacetError)
    end
  end

  describe "sort facet" do
    it "accepts valid sort values" do
      facets = described_class.parse(%w[sort price-asc])
      expect(facets).to eq("sort" => "price-asc")
    end

    it "rejects invalid sort values" do
      expect { described_class.parse(%w[sort invalid]) }.to raise_error(Artworks::FacetParser::InvalidFacetError)
    end
  end
end
