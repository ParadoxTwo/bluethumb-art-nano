# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Discovery flows", type: :system do
  it "lands on filtered browse after completing the style quiz" do
    create(:artwork, style: "abstract", price_cents: 75_000,
           width_cm: 80, height_cm: 100, title: "Quiz Match", slug: "quiz-match")
    create(:artwork, style: "landscape", price_cents: 75_000,
           title: "Quiz Miss", slug: "quiz-miss")

    visit discover_path
    choose "Abstract"
    click_button "Continue"
    choose "$500 – $1,000"
    click_button "Continue"
    choose "Medium (60–100 cm)"
    click_button "See results"

    expect(page).to have_current_path(%r{/artworks/style/abstract/price/500-1000/size/medium})
    expect(page).to have_content("Quiz Match")
    expect(page).not_to have_content("Quiz Miss")
  end

  it "skips optional size and lands on style and price facets only" do
    create(:artwork, style: "abstract", price_cents: 75_000, title: "Skip Size Match", slug: "skip-size-match")

    visit discover_path
    choose "Abstract"
    click_button "Continue"
    choose "$500 – $1,000"
    click_button "Continue"
    click_button "See results"

    expect(page).to have_current_path(%r{/artworks/style/abstract/price/500-1000})
    expect(page).not_to have_current_path(%r{/size/})
    expect(page).to have_content("Skip Size Match")
  end

  it "searches from the header form" do
    create(:artwork, title: "Header Search Hit", slug: "header-search-hit")

    visit root_path
    fill_in "Search artworks", with: "Header Search"
    page.driver.submit(:get, artworks_path, q: "Header Search")

    expect(page).to have_content("Header Search Hit")
  end

  it "saves an artwork to favourites across navigation" do
    artwork = create(:artwork, title: "Fav Piece", slug: "fav-piece")

    visit artwork_path(artwork.slug)
    click_button "Save"
    expect(page).to have_button("Saved")

    visit artworks_path
    visit artwork_path(artwork.slug)
    expect(page).to have_button("Saved")
  end
end
