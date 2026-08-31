# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Artworks", type: :request do
  let!(:abstract) { create(:artwork, style: "abstract", title: "Sunset Abstract") }
  let!(:landscape) { create(:artwork, style: "landscape", title: "Mountain Vista", slug: "mountain-vista") }

  describe "GET /artworks" do
    it "renders artwork tiles in HTML" do
      get artworks_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Sunset Abstract")
      expect(response.body).to include("Mountain Vista")
    end

    it "filters by style from URL segments" do
      get artworks_path(facets: "style/abstract")

      expect(response.body).to include("Sunset Abstract")
      expect(response.body).not_to include("Mountain Vista")
    end

    it "returns turbo frame content when requested" do
      get artworks_path(facets: "style/abstract"), headers: { "Turbo-Frame" => "artworks_results" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('turbo-frame id="artworks_results"')
      expect(response.body).to include("Sunset Abstract")
    end

    it "filters by price facet including 0-500" do
      affordable = create(:artwork, title: "Budget Piece", price_cents: 25_000, slug: "budget-piece")
      create(:artwork, title: "Premium Piece", price_cents: 600_000, slug: "premium-piece")

      get artworks_path(facets: "price/0-500")

      expect(response.body).to include("Budget Piece")
      expect(response.body).not_to include("Premium Piece")
    end

    it "sorts by price ascending via facet URL" do
      cheap = create(:artwork, title: "Cheap Sort", price_cents: 10_000, slug: "cheap-sort")
      dear = create(:artwork, title: "Dear Sort", price_cents: 900_000, slug: "dear-sort")

      get artworks_path(facets: "sort/price-asc")

      expect(response.body.index("Cheap Sort")).to be < response.body.index("Dear Sort")
    end

    it "searches by query param" do
      create(:artwork, title: "Unique Searchable Title", slug: "unique-searchable")

      get artworks_path, params: { q: "Unique Searchable" }

      expect(response.body).to include("Unique Searchable Title")
    end

    it "searches by artist name" do
      artist = create(:artist, name: "Unique Artist Name")
      create(:artwork, artist: artist, title: "Untitled Study", slug: "untitled-study")

      get artworks_path, params: { q: "Unique Artist" }

      expect(response.body).to include("Untitled Study")
    end
  end
end
