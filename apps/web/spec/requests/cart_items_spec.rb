# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Cart items", type: :request do
  let!(:artwork) { create(:artwork, title: "Cart Target", slug: "cart-target") }

  describe "POST /cart_items" do
    it "adds an available artwork to the session cart" do
      post cart_items_path, params: { artwork_id: artwork.id }

      expect(response).to redirect_to(artworks_path)
      follow_redirect!
      expect(response.body).to include("Cart (1)")
    end

    it "returns turbo_stream updating cart count" do
      post cart_items_path, params: { artwork_id: artwork.id }, headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include('turbo-stream action="update" target="cart_count"')
      expect(response.body).to include("Cart (1)")
    end

    it "returns 404 for sold artwork" do
      sold = create(:artwork, :sold, slug: "sold-cart-target")

      post cart_items_path, params: { artwork_id: sold.id }

      expect(response).to have_http_status(:not_found)
    end

    it "applies framing option when adding to cart" do
      post cart_items_path, params: { artwork_id: artwork.id, framing_option: "natural" }

      item = Cart.last.cart_items.first
      expect(item.quantity).to eq(1)
      expect(item.framing_option).to eq("natural")
    end

    it "increments quantity when adding the same artwork with the same framing" do
      post cart_items_path, params: { artwork_id: artwork.id, framing_option: "natural" }
      post cart_items_path, params: { artwork_id: artwork.id, framing_option: "natural" }

      expect(Cart.last.cart_items.count).to eq(1)
      item = Cart.last.cart_items.first
      expect(item.quantity).to eq(2)
      expect(item.framing_option).to eq("natural")
    end

    it "creates separate line items for different framing options" do
      post cart_items_path, params: { artwork_id: artwork.id, framing_option: "natural" }
      post cart_items_path, params: { artwork_id: artwork.id, framing_option: "black" }
      post cart_items_path, params: { artwork_id: artwork.id, framing_option: "white" }

      items = Cart.last.cart_items.order(:framing_option)
      expect(items.count).to eq(3)
      expect(items.map(&:framing_option)).to contain_exactly("natural", "black", "white")
      expect(items.map(&:quantity)).to all(eq(1))
    end

    it "includes framing surcharge in cart totals" do
      post cart_items_path, params: { artwork_id: artwork.id, framing_option: "natural" }

      get cart_path

      expect(response.body).to include("Framing (Natural)")
      expect(response.body).to include("+$250")
    end
  end

  describe "DELETE /cart_items/:id" do
    it "removes an item and returns turbo_stream" do
      post cart_items_path, params: { artwork_id: artwork.id }
      cart_item = Cart.last.cart_items.first

      delete cart_item_path(cart_item), headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('turbo-stream action="update" target="cart_count"')
      expect(response.body).to include("Cart (0)")
    end
  end
end
