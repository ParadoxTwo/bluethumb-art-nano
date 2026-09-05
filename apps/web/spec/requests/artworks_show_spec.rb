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

    it "renders the colour island mount point when swatches exist" do
      require "webmock/rspec"

      source = create(:artwork, :with_swatches, artist: artist, title: "Swatched", slug: "swatched")

      WebMock.disable_net_connect!
      stub_palette_similar(source.id, returning: [])

      get artwork_path(source.slug)

      expect(response.body).to include('data-island-component="ColourPicker"')
      expect(response.body).to include("#3366cc")
      expect(response.body).to include(artwork_colour_matches_path(source.slug))
    end

    it "omits the colour island when the artwork has no swatches" do
      artwork = create(:artwork, artist: artist, title: "No Palette", slug: "no-palette")

      get artwork_path(artwork.slug)

      expect(response.body).not_to include("data-island-component")
    end

    # Reproduces a live 500. A free Render instance can take ~30s to wake, and
    # while it does the edge in front of it answers 502 with an HTML page, not
    # JSON. The artwork page must lose its colour rail, not itself.
    it "still renders when the palette service answers with a non-JSON error page" do
      require "webmock/rspec"

      source = create(:artwork, :with_palette, artist: artist, title: "Waking Service", slug: "waking-service")

      WebMock.disable_net_connect!
      stub_request(:get, %r{http://localhost:9292/colour/similar/\d+}).to_return(
        status: 502,
        body: "<html><body><h1>502 Bad Gateway</h1></body></html>",
        headers: { "Content-Type" => "text/html" }
      )

      get artwork_path(source.slug)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Waking Service")
      expect(response.body).not_to include("More like this, by colour")
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
