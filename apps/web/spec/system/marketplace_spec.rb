# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Marketplace", type: :system do
  it "lists factory artworks on the browse page" do
    artwork = create(:artwork, title: "System Browse Piece", slug: "system-browse-piece")

    visit artworks_path

    expect(page).to have_content("System Browse Piece")
    expect(page).to have_content(artwork.artist.name)
  end

  it "filters results by style facet URL" do
    create(:artwork, style: "abstract", title: "Abstract Only", slug: "abstract-only")
    create(:artwork, style: "landscape", title: "Landscape Only", slug: "landscape-only")

    visit artworks_path(facets: "style/abstract")

    expect(page).to have_content("Abstract Only")
    expect(page).not_to have_content("Landscape Only")
  end

  it "adds an artwork to the cart from the detail page" do
    artwork = create(:artwork, title: "Cart Flow Piece", slug: "cart-flow-piece")

    visit artwork_path(artwork.slug)
    expect(page).to have_content("Cart (0)")

    click_button "Add to cart"

    expect(page).to have_content("Cart (1)")
  end

  it "completes the buyer journey from home to thank-you" do
    artwork = create(:artwork, title: "Journey Piece", slug: "journey-piece", price_cents: 50_000)

    visit root_path
    expect(page).to have_content("Take the style quiz")

    visit artwork_path(artwork.slug)
    click_button "Add to cart"

    visit cart_path
    expect(page).to have_content("Journey Piece")
    click_link "Checkout"

    fill_in "Name", with: "Demo Buyer"
    fill_in "Email", with: "buyer@example.com"
    fill_in "Street address", with: "1 Test St"
    fill_in "City", with: "Melbourne"
    fill_in "State", with: "VIC"
    fill_in "Postcode", with: "3000"
    click_button "Place order"

    expect(page).to have_content("Thank you")
  end
end
