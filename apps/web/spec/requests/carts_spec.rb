# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Cart", type: :request do
  it "shows line items and subtotal" do
    artwork = create(:artwork, title: "Cart Line Item", price_cents: 100_000)

    get artwork_path(artwork.slug)
    post cart_items_path, params: { artwork_id: artwork.id }

    get cart_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Cart Line Item")
    expect(response.body).to include("$1,000")
    expect(response.body).to include("Checkout")
  end

  it "shows quantity and unit price breakdown when the same item is added twice" do
    artwork = create(:artwork, title: "Duplicate Piece", price_cents: 50_000)

    get artwork_path(artwork.slug)
    post cart_items_path, params: { artwork_id: artwork.id, framing_option: "black" }
    post cart_items_path, params: { artwork_id: artwork.id, framing_option: "black" }

    get cart_path

    expect(response.body).to include("Duplicate Piece")
    expect(response.body).to include("× 2")
    expect(response.body).to include("$500 × 2")
    expect(response.body).to include("+$250 × 2")
    expect(response.body).to include("$1,500")
    expect(response.body).to include("Framing (Black)")
    expect(response.body).to include("$1,000")
    expect(response.body).to include("$500")
  end

  it "shows separate line items for different framing options" do
    artwork = create(:artwork, title: "Multi Frame Piece", price_cents: 50_000)

    get artwork_path(artwork.slug)
    post cart_items_path, params: { artwork_id: artwork.id, framing_option: "natural" }
    post cart_items_path, params: { artwork_id: artwork.id, framing_option: "black" }
    post cart_items_path, params: { artwork_id: artwork.id, framing_option: "white" }

    get cart_path

    expect(Cart.last.cart_items.count).to eq(3)
    expect(response.body).to include("Framing (Natural)")
    expect(response.body).to include("Framing (Black)")
    expect(response.body).to include("Framing (White)")
    expect(response.body).not_to include("× 3")
  end
end
