# frozen_string_literal: true

if Rails.env.development?
  artist_count = ENV.fetch("SEED_ARTIST_COUNT", 10).to_i
  artwork_count = ENV.fetch("SEED_ARTWORK_COUNT", 200).to_i

  if Artist.none?
    puts "Seeding #{artwork_count} artworks..."
    ArtworkGenerator.regenerate!(artist_count: artist_count, artwork_count: artwork_count)
  else
    puts "Catalogue already present (#{Artwork.count} artworks). Skipping seed."
  end
end
