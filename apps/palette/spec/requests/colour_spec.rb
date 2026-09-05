# frozen_string_literal: true

require "spec_helper"
require "securerandom"

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

    # Rails and this service have separate disks on Render, so the caller can
    # send the bytes rather than trusting that image_path_for can find them.
    it "extracts from an uploaded image when one is sent" do
      require "vips"

      path = File.join(Dir.tmpdir, "extract-upload-#{Process.pid}-#{SecureRandom.hex(4)}.png")
      Vips::Image.black(48, 48, bands: 3)
                 .linear([0.0, 0.0, 0.0], [40.0, 120.0, 220.0])
                 .cast(:uchar)
                 .write_to_file(path)

      post "/colour/extract", {
        artwork_id: "999999999",
        image: Rack::Test::UploadedFile.new(path, "image/png", original_filename: "artwork.png")
      }

      expect(last_response.status).to eq(200), last_response.body
      body = JSON.parse(last_response.body)
      expect(body["source"]).to eq("upload")
      expect(body["artwork_id"]).to eq(999_999_999)
      swatches = body.dig("palette", "swatches")
      expect(swatches).to be_an(Array)
      expect(swatches).not_to be_empty
      swatches.each do |swatch|
        expect(swatch["hex"]).to match(/\A#\h{6}\z/)
      end
    ensure
      File.delete(path) if path && File.exist?(path)
    end

    it "leaves no temporary file behind after an upload" do
      require "vips"

      before = Dir.glob(File.join(Dir.tmpdir, "extract-*")).size
      path = File.join(Dir.tmpdir, "extract-src-#{Process.pid}-#{SecureRandom.hex(4)}.png")
      Vips::Image.black(24, 24, bands: 3).cast(:uchar).write_to_file(path)

      post "/colour/extract", {
        artwork_id: "999999999",
        image: Rack::Test::UploadedFile.new(path, "image/png", original_filename: "artwork.png")
      }

      expect(Dir.glob(File.join(Dir.tmpdir, "extract-*")).size).to eq(before + 1) # only our source file
    ensure
      File.delete(path) if path && File.exist?(path)
    end

    it "rejects an upload the service will not accept" do
      path = File.join(Dir.tmpdir, "extract-bad-#{Process.pid}-#{SecureRandom.hex(4)}.txt")
      File.write(path, "not an image")

      post "/colour/extract", {
        artwork_id: "999999999",
        image: Rack::Test::UploadedFile.new(path, "text/plain", original_filename: "notes.txt")
      }

      expect(last_response.status).to eq(422)
      expect(JSON.parse(last_response.body).dig("error", "code")).to eq("validation_error")
    ensure
      File.delete(path) if path && File.exist?(path)
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
      require "vips"

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
