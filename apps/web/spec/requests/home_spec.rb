# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Home", type: :request do
  it "renders staff picks and quiz CTA" do
    create(:artwork, title: "Featured Piece", featured_at: Time.current)

    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Featured Piece")
    expect(response.body).to include("Take the style quiz")
  end
end
