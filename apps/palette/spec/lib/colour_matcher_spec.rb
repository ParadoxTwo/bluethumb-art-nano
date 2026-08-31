# frozen_string_literal: true

require "spec_helper"

RSpec.describe ColourMatcher do
  it "returns zero distance for identical colours" do
    lab = [50.0, 10.0, -5.0]
    expect(described_class.new.delta_e76(lab, lab)).to eq(0.0)
  end

  it "returns empty similar artworks in stub phase" do
    expect(described_class.new.similar_artworks(1)).to eq([])
  end
end
