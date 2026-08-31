# frozen_string_literal: true

namespace :artworks do
  desc "Regenerate synthetic catalogue (ARTIST_COUNT=50 ARTWORK_COUNT=500)"
  task regenerate: :environment do
    artist_count = ENV.fetch("ARTIST_COUNT", 50).to_i
    artwork_count = ENV.fetch("ARTWORK_COUNT", ENV.fetch("COUNT", 500)).to_i

    puts "Regenerating #{artwork_count} artworks for #{artist_count} artists..."
    ArtworkGenerator.regenerate!(artist_count: artist_count, artwork_count: artwork_count)
    puts "Done."
  end
end
