# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Artists", type: :request do
  describe "GET /artists/:slug" do
    it "renders artist profile and available artworks" do
      artist = create(:artist, name: "Studio Alpha", slug: "studio-alpha", bio: "Works in Melbourne")
      artwork = create(:artwork, artist: artist, title: "Gallery Piece", slug: "gallery-piece")
      create(:artwork, :sold, artist: artist, title: "Sold Work", slug: "sold-work")

      get artist_path(artist.slug)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Studio Alpha")
      expect(response.body).to include("Works in Melbourne")
      expect(response.body).to include("Gallery Piece")
      expect(response.body).not_to include("Sold Work")
    end
  end
end
