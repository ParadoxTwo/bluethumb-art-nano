# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Checkout", type: :request do
  it "places an order and shows thank-you page" do
    artwork = create(:artwork, title: "Checkout Piece")

    post cart_items_path, params: { artwork_id: artwork.id }
    post checkout_path, params: {
      contact_name: "Demo Buyer",
      contact_email: "buyer@example.com",
      address_line1: "1 Test St",
      address_city: "Melbourne",
      address_state: "VIC",
      address_postcode: "3000"
    }

    expect(response).to redirect_to(checkout_thank_you_path)
    follow_redirect!

    expect(response.body).to include("Thank you")
    expect(response.body).to include("buyer@example.com")
  end

  describe "empty cart guard" do
    it "redirects GET /checkout when the cart is empty" do
      get checkout_path

      expect(response).to redirect_to(cart_path)
      follow_redirect!
      expect(response.body).to include("Your cart is empty.")
    end

    it "redirects POST /checkout when the cart is empty" do
      post checkout_path, params: {
        contact_name: "Demo Buyer",
        contact_email: "buyer@example.com",
        address_line1: "1 Test St",
        address_city: "Melbourne",
        address_state: "VIC",
        address_postcode: "3000"
      }

      expect(response).to redirect_to(cart_path)
      follow_redirect!
      expect(response.body).to include("Your cart is empty.")
    end
  end

  describe "GET /checkout/thank-you" do
    it "redirects when there is no recent order in session" do
      get checkout_thank_you_path

      expect(response).to redirect_to(artworks_path)
      follow_redirect!
      expect(response.body).to include("No recent order found.")
    end
  end
end
