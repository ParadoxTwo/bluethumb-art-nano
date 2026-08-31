# frozen_string_literal: true

namespace :palettes do
  desc "Extract palette data for all artworks via palette service"
  task extract: :environment do
    client = PaletteClient.new
    scope = Artwork.available.includes(image_attachment: :blob)
    total = scope.count
    puts "Extracting palettes for #{total} artworks..."

    scope.find_each.with_index do |artwork, index|
      next unless artwork.image.attached?

      begin
        client.extract(artwork_id: artwork.id, force: true)
        print "." if ((index + 1) % 10).zero?
      rescue PaletteClient::Error => e
        warn "\nSkipping artwork #{artwork.id}: #{e.message}"
      end
    end

    puts "\nDone."
  end
end
