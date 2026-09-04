# frozen_string_literal: true

require "spec_helper"
require "securerandom"
require "vips"

RSpec.describe "Colour API", type: :request do
  describe "POST /colour/extract" do
    it "returns not found when artwork has no image" do
      post "/colour/extract", { artwork_id: 999_999_999 }.to_json, "CONTENT_TYPE" => "application/json"

      expect(last_response.status).to eq(404)
      body = JSON.parse(last_response.body)
      expect(body.dig("error", "code")).to eq("not_found")
    end

    it "returns 422 for invalid params" do
      post "/colour/extract", {}.to_json, "CONTENT_TYPE" => "application/json"

      expect(last_response.status).to eq(422)
      body = JSON.parse(last_response.body)
      expect(body.dig("error", "code")).to eq("validation_error")
    end
  end

  describe "GET /colour/similar/:artwork_id" do
    it "returns ranked neighbours" do
      get "/colour/similar/1"

      expect(last_response.status).to eq(200)
      body = JSON.parse(last_response.body)
      expect(body).to include("artworks", "meta")
      expect(body["meta"]).to include("count", "query_ms")
    end

    it "accepts a seed colour and echoes it in meta" do
      get "/colour/similar/1", { hex: "#3366cc" }

      expect(last_response.status).to eq(200)
      body = JSON.parse(last_response.body)
      expect(body.dig("meta", "seed", "hex")).to eq("#3366cc")
      expect(body.dig("meta", "seed", "lab")).to include("l", "a", "b")
    end

    it "rejects a malformed seed colour" do
      get "/colour/similar/1", { hex: "octarine" }

      expect(last_response.status).to eq(422)
      body = JSON.parse(last_response.body)
      expect(body.dig("error", "code")).to eq("validation_error")
    end
  end

  describe "POST /colour/match-room" do
    it "returns 422 when no image is uploaded" do
      post "/colour/match-room", {}.to_json, "CONTENT_TYPE" => "application/json"

      expect(last_response.status).to eq(422)
      body = JSON.parse(last_response.body)
      expect(body.dig("error", "code")).to eq("validation_error")
    end

    it "extracts a room palette and ranks artworks" do
      path = File.join(Dir.tmpdir, "match-room-#{Process.pid}-#{SecureRandom.hex(4)}.png")
      Vips::Image.black(48, 48, bands: 3)
                 .linear([0.0, 0.0, 0.0], [40.0, 120.0, 220.0])
                 .cast(:uchar)
                 .write_to_file(path)

      post "/colour/match-room", {
        image: Rack::Test::UploadedFile.new(path, "image/png", original_filename: "room.png")
      }

      expect(last_response.status).to eq(200), last_response.body
      body = JSON.parse(last_response.body)
      expect(body).to include("artworks", "palette", "meta")
      expect(body["palette"]).to include("centroid", "swatches", "hue_family")
      expect(body.dig("palette", "hue_family")).to eq("blue")
      expect(body["meta"]).to include("count", "query_ms")
    ensure
      File.delete(path) if path && File.exist?(path)
    end
  end
end
