# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Health", type: :request do
  it "returns ok" do
    get "/health"

    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)).to eq("status" => "ok")
  end
end
