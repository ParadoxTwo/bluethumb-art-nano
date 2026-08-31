# frozen_string_literal: true

require "spec_helper"

RSpec.describe ColourMatcher do
  subject(:matcher) { described_class.new }

  describe "#delta_e76" do
    it "returns zero distance for identical colours" do
      lab = [50.0, 10.0, -5.0]
      expect(matcher.delta_e76(lab, lab)).to eq(0.0)
    end

    it "grows with perceptual separation" do
      near = matcher.delta_e76([50.0, 10.0, -5.0], [52.0, 11.0, -4.0])
      far = matcher.delta_e76([50.0, 10.0, -5.0], [20.0, -40.0, 60.0])

      expect(far).to be > near
    end
  end

  describe "#lab_for_hex" do
    it "converts white to maximum lightness and neutral chroma" do
      l, a, b = matcher.lab_for_hex("#ffffff")

      expect(l).to be_within(0.5).of(100.0)
      expect(a).to be_within(0.5).of(0.0)
      expect(b).to be_within(0.5).of(0.0)
    end

    it "converts black to zero lightness" do
      expect(matcher.lab_for_hex("#000000").first).to be_within(0.5).of(0.0)
    end

    it "places pure red in the positive a* (red-green) axis" do
      _l, a, _b = matcher.lab_for_hex("#ff0000")

      expect(a).to be > 50
    end

    it "accepts a hex without the leading hash" do
      expect(matcher.lab_for_hex("ff0000")).to eq(matcher.lab_for_hex("#ff0000"))
    end

    it "rejects anything that is not a 6-digit hex colour" do
      expect { matcher.lab_for_hex("blue") }.to raise_error(described_class::InvalidHexError)
      expect { matcher.lab_for_hex("#fff") }.to raise_error(described_class::InvalidHexError)
    end
  end

  describe "#rank" do
    let(:candidates) do
      [
        { id: 3, l: 50.0, a: 10.0, b: -5.0 },   # exact match
        { id: 1, l: 55.0, a: 12.0, b: -3.0 },   # near
        { id: 2, l: 10.0, a: -40.0, b: 60.0 }   # far
      ]
    end

    it "orders candidates by ascending perceptual distance" do
      ranked = matcher.rank(candidates, [50.0, 10.0, -5.0])

      expect(ranked.map { |entry| entry[:id] }).to eq([3, 1, 2])
      expect(ranked.first[:distance]).to eq(0.0)
    end

    it "honours the limit" do
      expect(matcher.rank(candidates, [50.0, 10.0, -5.0], limit: 2).size).to eq(2)
    end

    it "breaks ties on id so repeated queries return a stable order" do
      tied = [
        { id: 9, l: 50.0, a: 10.0, b: -5.0 },
        { id: 4, l: 50.0, a: 10.0, b: -5.0 }
      ]

      expect(matcher.rank(tied, [50.0, 10.0, -5.0]).map { |entry| entry[:id] }).to eq([4, 9])
    end

    it "skips candidates with no palette data" do
      incomplete = [{ id: 7, l: nil, a: nil, b: nil }]

      expect(matcher.rank(incomplete, [50.0, 10.0, -5.0])).to be_empty
    end
  end

  describe "#similar_artworks" do
    it "returns nothing for an artwork that is not in the database" do
      expect(matcher.similar_artworks(-1)).to eq([])
    end
  end
end
