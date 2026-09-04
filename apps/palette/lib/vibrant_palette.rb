# frozen_string_literal: true

# MMCQ-style palette extraction backed by libvips.
#
# Bluethumb's public docs describe a `vibrant_palette` gem for median-cut
# swatches. That gem is not published on RubyGems, so this module provides the
# same role for the demo: load pixels with ruby-vips, quantize into a small
# palette, and return population-weighted swatches. PaletteExtractor is the
# only caller — colour math still funnels through one place.
module VibrantPalette
  BINS = 16
  DEFAULT_COUNT = 6
  MAX_EDGE = 160

  Swatch = Data.define(:r, :g, :b, :population)

  class Error < StandardError; end

  module_function

  def extract(path, color_count: DEFAULT_COUNT)
    raise Error, "image not found: #{path}" unless path && File.file?(path)

    require "vips"

    image = Vips::Image.new_from_file(path.to_s)
    image = image.colourspace(:srgb) if image.interpretation != :srgb
    # PNGs often load as 16-bit; hist bins assume 8-bit channels.
    image = (image / 256).cast(:uchar) if image.format == :ushort
    image = image.cast(:uchar) if image.format != :uchar
    image = image.extract_band(0, n: 3) if image.bands > 3
    image = image.thumbnail_image(MAX_EDGE, height: MAX_EDGE, size: :down) if [image.width, image.height].max > MAX_EDGE

    histogram = image.hist_find_ndim(bins: BINS).bandunfold
    _, colours = histogram.max(size: [color_count * 3, 24].max, out_array: true, x_array: true, y_array: true)

    # After bandunfold, x packs red and blue bin indices; y is green.
    swatches = Array(colours["out_array"]).zip(colours["x_array"], colours["y_array"]).filter_map do |count, x, y|
      next if count.to_f <= 0

      x = x.to_i
      y = y.to_i
      r = (BINS / 2) + (BINS * (x / BINS))
      g = (BINS / 2) + (BINS * y)
      b = (BINS / 2) + (BINS * (x % BINS))
      Swatch.new(r: r.clamp(0, 255), g: g.clamp(0, 255), b: b.clamp(0, 255), population: count.to_f)
    end

    raise Error, "no colour samples found" if swatches.empty?

    merge_similar(swatches).sort_by { |swatch| -swatch.population }.first(color_count)
  rescue LoadError, Vips::Error => e
    raise Error, e.message
  end

  def merge_similar(swatches, threshold: 28)
    merged = []
    swatches.each do |swatch|
      twin_index = merged.index { |other| rgb_distance(other, swatch) < threshold }
      if twin_index
        twin = merged[twin_index]
        total = twin.population + swatch.population
        merged[twin_index] = Swatch.new(
          r: ((twin.r * twin.population + swatch.r * swatch.population) / total).round,
          g: ((twin.g * twin.population + swatch.g * swatch.population) / total).round,
          b: ((twin.b * twin.population + swatch.b * swatch.population) / total).round,
          population: total
        )
      else
        merged << swatch
      end
    end
    merged
  end
  private_class_method :merge_similar

  def rgb_distance(a, b)
    Math.sqrt((a.r - b.r)**2 + (a.g - b.g)**2 + (a.b - b.b)**2)
  end
  private_class_method :rgb_distance
end
