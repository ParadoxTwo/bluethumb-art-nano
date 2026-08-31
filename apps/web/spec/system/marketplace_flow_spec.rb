# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Marketplace cart flows", type: :system do
  it "removes an item from the cart" do
    artwork = create(:artwork, title: "Remove Me", slug: "remove-me")

    visit artwork_path(artwork.slug)
    click_button "Add to cart"
    visit cart_path
    expect(page).to have_content("Remove Me")

    click_button "Remove"

    expect(page).to have_content("Your cart is empty")
    expect(page).to have_content("Cart (0)")
  end

  it "does not add artwork to cart when selecting framing only" do
    artwork = create(:artwork, title: "Unframed Piece", slug: "unframed-piece", price_cents: 50_000)

    visit artwork_path(artwork.slug)
    choose "Natural"

    expect(page).to have_content("Cart (0)")
    expect(CartItem.count).to eq(0)

    click_button "Add to cart"

    expect(page).to have_content("Cart (1)")
    visit cart_path
    expect(page).to have_content("Framing (Natural)")
    expect(page).to have_content("+$250")
  end

  it "adds framing surcharge to cart total" do
    artwork = create(:artwork, title: "Framed Piece", slug: "framed-piece", price_cents: 50_000)

    visit artwork_path(artwork.slug)
    choose "Natural"
    click_button "Add to cart"
    visit cart_path

    expect(page).to have_content("Framing (Natural)")
    expect(page).to have_content("+$250")
    expect(page).to have_content("$750")
  end

  it "does not increment quantity when switching framing before adding to cart" do
    artwork = create(:artwork, title: "Switch Frame", slug: "switch-frame", price_cents: 50_000)

    visit artwork_path(artwork.slug)
    choose "Natural"
    choose "Black"
    click_button "Add to cart"

    expect(page).to have_content("Cart (1)")
    visit cart_path
    expect(page).to have_content("Framing (Black)")
  end

  it "renders sold artwork without add-to-cart" do
    artwork = create(:artwork, :sold, title: "Sold System Piece", slug: "sold-system-piece")

    visit artwork_path(artwork.slug)

    expect(page).to have_no_button("Add to cart")
    expect(page).to have_content("This artwork has sold")
  end
end
