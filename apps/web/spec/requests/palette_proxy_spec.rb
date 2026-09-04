# frozen_string_literal: true

require "rails_helper"
require "webmock/rspec"

RSpec.describe "Palette proxy", type: :request do
  before { WebMock.disable_net_connect! }

  describe "GET /palette/health" do
    it "forwards to the palette service" do
      stub_request(:get, "http://localhost:9292/health")
        .to_return(status: 200, body: { status: "ok" }.to_json, headers: { "Content-Type" => "application/json" })

      get "/palette/health"

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq("status" => "ok")
    end

    it "returns 503 when the palette service times out" do
      stub_request(:get, "http://localhost:9292/health").to_timeout

      get "/palette/health"

      expect(response).to have_http_status(:service_unavailable)
    end

    it "returns 503 when palette service is unavailable" do
      stub_request(:get, "http://localhost:9292/health").to_raise(Errno::ECONNREFUSED)

      get "/palette/health"

      expect(response).to have_http_status(:service_unavailable)
      expect(JSON.parse(response.body)).to eq(
        "error" => { "code" => "service_unavailable", "message" => "Palette service unavailable" }
      )
    end
  end

  describe "GET /palette/colour/similar/:id" do
    it "forwards to the palette service" do
      stub_request(:get, "http://localhost:9292/colour/similar/42")
        .to_return(status: 200, body: { artworks: [] }.to_json, headers: { "Content-Type" => "application/json" })

      get "/palette/colour/similar/42"

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq("artworks" => [])
    end
  end

  describe "POST /palette/colour/extract" do
    it "forwards JSON body to the palette service" do
      stub_request(:post, "http://localhost:9292/colour/extract")
        .with(body: { artwork_id: 7, force: false }.to_json)
        .to_return(status: 200, body: { status: "ok" }.to_json, headers: { "Content-Type" => "application/json" })

      post "/palette/colour/extract", params: { artwork_id: 7, force: false }, as: :json

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq("status" => "ok")
    end
  end
end
