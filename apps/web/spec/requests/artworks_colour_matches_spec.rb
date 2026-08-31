# frozen_string_literal: true

require "rails_helper"
require "webmock/rspec"

RSpec.describe "Artwork colour matches", type: :request do
  let(:artist) { create(:artist, name: "Jane Doe") }
  let(:source) { create(:artwork, :with_swatches, artist: artist, title: "Source", slug: "source") }

  before { WebMock.disable_net_connect! }

  describe "GET /artworks/:slug/colour-matches" do
    it "returns ranked artworks for a seed colour" do
      neighbour = create(:artwork, artist: artist, title: "Neighbour", slug: "neighbour", price_cents: 120_000)
      stub_palette_similar(source.id, returning: [neighbour], hex: "3366cc")

      get artwork_colour_matches_path(source.slug), params: { hex: "#3366cc" }

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["meta"]).to eq("seed" => "#3366cc", "count" => 1)
      expect(body["artworks"].first).to include(
        "id" => neighbour.id,
        "title" => "Neighbour",
        "artist" => "Jane Doe",
        "url" => artwork_path(neighbour.slug)
      )
    end

    it "forwards the seed colour to the palette service without the leading hash" do
      stub_palette_similar(source.id, returning: [], hex: "3366cc")

      get artwork_colour_matches_path(source.slug), params: { hex: "#3366cc" }

      expect(
        a_request(:get, "http://localhost:9292/colour/similar/#{source.id}")
          .with(query: { "hex" => "3366cc" })
      ).to have_been_made
    end

    it "falls back to the artwork's own palette when no colour is given" do
      neighbour = create(:artwork, artist: artist, title: "Centroid Neighbour", slug: "centroid-neighbour")
      stub_palette_similar(source.id, returning: [neighbour])

      get artwork_colour_matches_path(source.slug)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["meta"]["seed"]).to be_nil
      expect(response.parsed_body["artworks"].first["title"]).to eq("Centroid Neighbour")
    end

    it "never returns sold artworks" do
      sold = create(:artwork, :sold, artist: artist, title: "Sold", slug: "sold-neighbour")
      stub_palette_similar(source.id, returning: [sold], hex: "3366cc")

      get artwork_colour_matches_path(source.slug), params: { hex: "#3366cc" }

      expect(response.parsed_body["artworks"]).to be_empty
    end

    it "rejects a malformed colour without calling the palette service" do
      get artwork_colour_matches_path(source.slug), params: { hex: "octarine" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("error", "code")).to eq("invalid_colour")
      expect(a_request(:get, %r{colour/similar})).not_to have_been_made
    end

    it "returns 404 for an unknown artwork" do
      get artwork_colour_matches_path("does-not-exist")

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body.dig("error", "code")).to eq("not_found")
    end

    it "returns 503 when the palette service is unavailable" do
      stub_palette_unavailable

      get artwork_colour_matches_path(source.slug), params: { hex: "#3366cc" }

      expect(response).to have_http_status(:service_unavailable)
      expect(response.parsed_body.dig("error", "code")).to eq("palette_unavailable")
    end
  end
end
