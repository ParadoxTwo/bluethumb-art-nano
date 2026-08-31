# frozen_string_literal: true

require "rails_helper"
require "webmock/rspec"

RSpec.describe PaletteClient do
  before { WebMock.disable_net_connect! }

  it "returns health status" do
    stub_request(:get, "http://localhost:9292/health")
      .to_return(status: 200, body: { status: "ok" }.to_json, headers: { "Content-Type" => "application/json" })

    expect(described_class.new.health).to eq("status" => "ok")
  end

  it "returns similar artworks" do
    stub_request(:get, "http://localhost:9292/colour/similar/5")
      .to_return(
        status: 200,
        body: { artworks: [{ id: 9, distance: 0.2 }] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    expect(described_class.new.similar(5)).to eq("artworks" => [{ "id" => 9, "distance" => 0.2 }])
  end

  it "extracts palette data for an artwork" do
    stub_request(:post, "http://localhost:9292/colour/extract")
      .with(body: { artwork_id: 3, force: true }.to_json)
      .to_return(status: 200, body: { status: "ok" }.to_json, headers: { "Content-Type" => "application/json" })

    expect(described_class.new.extract(artwork_id: 3, force: true)).to eq("status" => "ok")
  end

  it "raises with palette error message on failure" do
    stub_request(:get, "http://localhost:9292/colour/similar/1")
      .to_return(
        status: 422,
        body: { error: { code: "missing_palette", message: "No palette data" } }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    expect { described_class.new.similar(1) }.to raise_error(PaletteClient::Error, "No palette data")
  end
end
