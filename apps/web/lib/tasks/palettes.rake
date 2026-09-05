# frozen_string_literal: true

namespace :palettes do
  desc "Extract palette data for all artworks via the palette service " \
       "(PALETTE_EXTRACT_UPLOAD=1 sends image bytes instead of naming the artwork)"
  task extract: :environment do
    # Naming the artwork is cheaper, but it only works when the palette service
    # can open the same files Rails wrote. On Render the two services have
    # separate disks, so the bytes have to travel with the request.
    upload = ActiveModel::Type::Boolean.new.cast(ENV["PALETTE_EXTRACT_UPLOAD"]).present?

    client = PaletteClient.new
    scope = Artwork.available.includes(image_attachment: :blob)
    total = scope.count
    extracted = 0
    failures = []

    puts "Extracting palettes for #{total} artworks (#{upload ? 'uploading images' : 'by artwork id'})..."

    scope.find_each.with_index do |artwork, index|
      next unless artwork.image.attached?

      begin
        if upload
          extract_by_upload(client, artwork)
        else
          client.extract(artwork_id: artwork.id, force: true)
        end
        extracted += 1
        print "." if ((index + 1) % 10).zero?
      rescue PaletteClient::Error => e
        failures << "#{artwork.id}: #{e.message}"
      end
    end

    puts "\nExtracted #{extracted}/#{total}."

    next if failures.empty?

    warn "#{failures.size} artwork(s) could not be extracted. First few:"
    failures.first(5).each { |failure| warn "  #{failure}" }
  end

  # blob.open works whatever the storage service is, and cleans up after
  # itself, so this does not assume the images are on local disk either.
  def extract_by_upload(client, artwork)
    artwork.image.blob.open do |file|
      client.extract(
        artwork_id: artwork.id,
        force: true,
        image: {
          path: file.path,
          content_type: artwork.image.content_type,
          filename: artwork.image.filename.to_s
        }
      )
    end
  end
end
