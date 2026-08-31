# frozen_string_literal: true

FactoryBot.define do
  factory :artist do
    sequence(:name) { |n| "Artist #{n}" }
    sequence(:slug) { |n| "artist-#{n}" }
    bio { "Synthetic bio" }
    location { "Melbourne, VIC" }
  end

  factory :artwork do
    association :artist
    sequence(:title) { |n| "Artwork #{n}" }
    sequence(:slug) { |n| "artwork-#{n}" }
    description { "Synthetic description" }
    width_cm { 80 }
    height_cm { 100 }
    depth_cm { 4 }
    weight_kg { 2.5 }
    medium { Artwork::MEDIUMS.first }
    style { Artwork::STYLES.first }
    price_cents { 150_000 }
    status { "available" }
    orientation { "portrait" }
    generation_seed { { index: 1 } }

    trait :sold do
      status { "sold" }
    end

    trait :with_palette do
      palette_centroid_l { 45.0 }
      palette_centroid_a { 12.0 }
      palette_centroid_b { -8.0 }
      palette_data { { "hue_family" => "blue" } }
    end
  end

  factory :cart do
    sequence(:session_id) { |n| "session-#{n}" }
  end

  factory :cart_item do
    association :cart
    association :artwork
    quantity { 1 }
  end
end
