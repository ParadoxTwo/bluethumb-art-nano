# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Match room", type: :request do
  describe "GET /match-room" do
    it "renders the SSR shell and island mount" do
      get match_room_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Match my room")
      expect(response.body).to include('data-island-component="RoomMatch"')
      expect(response.body).to include(match_room_path)
    end
  end

  describe "POST /match-room" do
    it "returns ranked artworks with presentation fields" do
      artist = create(:artist)
      match = create(:artwork, :with_palette, artist: artist, title: "Room Neighbour", slug: "room-neighbour")
      stub_palette_match_room(returning: [match], palette: {
        "hue_family" => "blue",
        "centroid" => { "l" => 50, "a" => 10, "b" => -20 },
        "swatches" => [{ "hex" => "#2864dc", "population" => 1.0 }]
      })

      file = Tempfile.new(["room", ".png"])
      file.write("fake-image")
      file.rewind

      post match_room_path, params: {
        image: Rack::Test::UploadedFile.new(file.path, "image/png", original_filename: "room.png")
      }

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["artworks"].first).to include(
        "title" => "Room Neighbour",
        "url" => artwork_path(match)
      )
      expect(body.dig("palette", "hue_family")).to eq("blue")
    ensure
      file.close!
    end

    it "returns 422 when no image is provided" do
      post match_room_path

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("error", "code")).to eq("validation_error")
    end

    it "returns 503 when the palette service is down" do
      stub_palette_unavailable
      file = Tempfile.new(["room", ".png"])
      file.write("fake")
      file.rewind

      post match_room_path, params: {
        image: Rack::Test::UploadedFile.new(file.path, "image/png", original_filename: "room.png")
      }

      expect(response).to have_http_status(:service_unavailable)
    ensure
      file.close!
    end
  end
end
