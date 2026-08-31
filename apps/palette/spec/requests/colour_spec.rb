# frozen_string_literal: true

require "spec_helper"

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
  end

  describe "POST /colour/match-room" do
    it "returns a Phase 1 stub" do
      post "/colour/match-room", {}.to_json, "CONTENT_TYPE" => "application/json"

      expect(last_response.status).to eq(501)
      body = JSON.parse(last_response.body)
      expect(body.dig("error", "code")).to eq("not_implemented")
    end
  end
end
