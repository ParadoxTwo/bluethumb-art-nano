# frozen_string_literal: true

require "chunky_png"

class ArtworkGenerator
  class VipsUnavailableError < StandardError; end

  AU_LOCATIONS = [
    "Melbourne, VIC", "Sydney, NSW", "Brisbane, QLD", "Perth, WA",
    "Adelaide, SA", "Hobart, TAS", "Darwin, NT", "Canberra, ACT"
  ].freeze

  FEATURED_COUNT = 8

  def self.regenerate!(artist_count: 50, artwork_count: 500)
    new.regenerate!(artist_count: artist_count, artwork_count: artwork_count)
  end

  def regenerate!(artist_count:, artwork_count:)
    ActiveRecord::Base.transaction do
      CartItem.delete_all
      Cart.delete_all
      Artwork.find_each do |artwork|
        artwork.image.purge if artwork.image.attached?
        artwork.gallery_images.purge if artwork.gallery_images.attached?
      end
      Artwork.delete_all
      Artist.delete_all

      artists = create_artists(artist_count)
      create_artworks(artists, artwork_count)
    end
  end

  private

  def create_artists(count)
    count.times.map do
      name = Faker::Name.name
      Artist.create!(
        name: name,
        bio: Faker::Lorem.paragraph(sentence_count: 3),
        location: AU_LOCATIONS.sample
      )
    end
  end

  def create_artworks(artists, count)
    featured_indices = (0...count).to_a.sample([FEATURED_COUNT, count].min)

    count.times do |i|
      artist = artists.sample
      seed = Random.new(i + 42)
      style = Artwork::STYLES.sample(random: seed)
      medium = Artwork::MEDIUMS.sample(random: seed)
      width = seed.rand(60..120)
      height = seed.rand(60..150)
      orientation = if width > height
                      "landscape"
                    elsif width < height
                      "portrait"
                    else
                      "square"
                    end

      base_colours = {
        r: seed.rand(40..220),
        g: seed.rand(40..220),
        b: seed.rand(40..220)
      }
      palette = PaletteDataBuilder.from_rgb(base_colours[:r], base_colours[:g], base_colours[:b])

      artwork = Artwork.create!(
        artist: artist,
        title: "#{style.titleize} #{medium.titleize} ##{i + 1}",
        description: Faker::Lorem.paragraph(sentence_count: 2),
        width_cm: width,
        height_cm: height,
        depth_cm: seed.rand(2..8),
        weight_kg: (seed.rand(0.5..12.0)).round(2),
        medium: medium,
        style: style,
        price_cents: seed.rand(20_000..800_000),
        status: seed.rand < 0.05 ? "sold" : "available",
        orientation: orientation,
        generation_seed: { index: i, rng: seed.rand(1_000_000), base_colours: base_colours },
        featured_at: featured_indices.include?(i) ? Time.current - i.hours : nil,
        popularity_score: seed.rand(0..100),
        palette_data: palette[:data],
        palette_centroid_l: palette[:l],
        palette_centroid_a: palette[:a],
        palette_centroid_b: palette[:b],
        palette_extracted_at: Time.current
      )

      attach_images!(artwork, seed, base_colours)
    end
  end

  def attach_images!(artwork, seed, base_colours)
    png = generate_png(seed, base_colours)
    artwork.image.attach(
      io: StringIO.new(png),
      filename: "#{artwork.slug}.png",
      content_type: "image/png"
    )

    detail_seed = Random.new(seed.rand(1_000_000))
    detail_png = generate_png(detail_seed, base_colours.merge(r: base_colours[:r] + 20))
    artwork.gallery_images.attach(
      io: StringIO.new(detail_png),
      filename: "#{artwork.slug}-detail.png",
      content_type: "image/png"
    )
  end

  def generate_png(seed, base_colours)
    width = 800
    height = 1000
    png = ChunkyPNG::Image.new(width, height, ChunkyPNG::Color::WHITE)

    base_r = base_colours[:r]
    base_g = base_colours[:g]
    base_b = base_colours[:b]

    width.times do |x|
      height.times do |y|
        noise = seed.rand(-30..30)
        r = [[base_r + noise + (x / 8), 0].max, 255].min
        g = [[base_g + noise + (y / 10), 0].max, 255].min
        b = [[base_b + noise, 0].max, 255].min
        png[x, y] = ChunkyPNG::Color.rgb(r, g, b)
      end
    end

    seed.rand(3..8).times do
      cx = seed.rand(0...width)
      cy = seed.rand(0...height)
      radius = seed.rand(40..180)
      color = ChunkyPNG::Color.rgb(seed.rand(255), seed.rand(255), seed.rand(255))
      png.circle(cx, cy, radius, color, color)
    end

    png.to_blob
  end
end
