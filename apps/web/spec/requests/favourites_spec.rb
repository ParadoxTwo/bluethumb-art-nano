# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Favourites", type: :request do
  let!(:artwork) { create(:artwork, title: "Favourite Target", slug: "favourite-target") }

  describe "POST /favourites" do
    it "adds the artwork id to the session" do
      post favourites_path, params: { artwork_id: artwork.id }

      expect(response).to redirect_to(artwork_path(artwork))
      follow_redirect!
      expect(response.body).to include("Saved")
    end

    it "does not duplicate ids on repeat save" do
      post favourites_path, params: { artwork_id: artwork.id }
      post favourites_path, params: { artwork_id: artwork.id }

      get artwork_path(artwork.slug)
      expect(response.body).to include("Saved")
      expect(response.body).not_to match(/>\s*Save\s*</)
    end
  end

  describe "DELETE /favourites/:artwork_id" do
    it "removes the artwork id from the session" do
      post favourites_path, params: { artwork_id: artwork.id }

      delete favourite_path(artwork_id: artwork.id)

      expect(response).to redirect_to(artwork_path(artwork))
      follow_redirect!
      expect(response.body).to match(/>\s*Save\s*</)
    end
  end
end
