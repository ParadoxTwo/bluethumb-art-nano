# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Discover quiz", type: :request do
  it "redirects to composed facet URL after three steps" do
    patch discover_path, params: { step: 1, style: "abstract" }
    expect(response).to redirect_to(discover_path(step: 2))

    patch discover_path, params: { step: 2, price: "500-1000" }
    expect(response).to redirect_to(discover_path(step: 3))

    patch discover_path, params: { step: 3, size: "medium" }
    expect(response).to redirect_to(%r{/artworks/style/abstract/price/500-1000/size/medium})
  end

  it "redirects to style and price facets when size is skipped" do
    patch discover_path, params: { step: 1, style: "abstract" }
    patch discover_path, params: { step: 2, price: "500-1000" }
    patch discover_path, params: { step: 3 }

    expect(response).to redirect_to(%r{/artworks/style/abstract/price/500-1000})
    expect(response.location).not_to match(%r{/size/})
  end
end
