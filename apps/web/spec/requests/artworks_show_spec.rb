# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Artwork show", type: :request do
  let(:artist) { create(:artist, name: "Jane Doe", slug: "jane-doe") }

  describe "GET /artworks/:slug" do
    it "renders an available artwork with add-to-cart" do
      artwork = create(:artwork, artist: artist, title: "Blue Horizon", slug: "blue-horizon")

      get artwork_path(artwork.slug)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Blue Horizon")
      expect(response.body).to include("Jane Doe")
      expect(response.body).to include("Add to cart")
    end

    it "renders sold artwork without add-to-cart" do
      artwork = create(:artwork, :sold, artist: artist, title: "Sold Piece", slug: "sold-piece")

      get artwork_path(artwork.slug)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Sold Piece")
      expect(response.body).to include("Sold")
      expect(response.body).not_to include("Add to cart")
    end

    it "renders similar-by-colour section when palette data is present" do
      require "webmock/rspec"

      source = create(:artwork, :with_palette, artist: artist, title: "Colour Source", slug: "colour-source")
      similar = create(:artwork, title: "Colour Neighbour", slug: "colour-neighbour")

      WebMock.disable_net_connect!
      stub_palette_similar(source.id, returning: [similar])

      get artwork_path(source.slug)

      expect(response.body).to include("More like this, by colour")
      expect(response.body).to include("Colour Neighbour")
    end

    it "omits similar-by-colour section when palette service is unavailable" do
      require "webmock/rspec"

      source = create(:artwork, :with_palette, artist: artist, title: "Palette Down", slug: "palette-down")

      WebMock.disable_net_connect!
      stub_palette_unavailable

      get artwork_path(source.slug)

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("More like this, by colour")
    end
  end
end
