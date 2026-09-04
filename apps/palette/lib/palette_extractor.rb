# frozen_string_literal: true

require "json"
require "time"
require_relative "vibrant_palette"

class PaletteExtractor
  # HSV-style buckets (red at 0°, blue near 240°). hue_family_for_rgb converts
  # the source RGB through HSV before bucketing — CIELAB hue angles are a
  # different wheel and misfile primaries when used here.
  HUE_FAMILIES = {
    (0..15) => "red",
    (16..45) => "orange",
    (46..70) => "yellow",
    (71..160) => "green",
    (161..250) => "blue",
    (251..330) => "purple",
    (331..360) => "red"
  }.freeze

  # Below this HSV saturation a colour reads as neutral to a buyer, regardless
  # of the (meaningless) hue angle on a grey.
  NEUTRAL_SATURATION = 0.12
  NEUTRAL_VALUE = 0.08

  def extract(image_path)
    return :not_implemented unless image_path && File.file?(image_path)

    swatches = VibrantPalette.extract(image_path)
    return :not_implemented if swatches.empty?

    from_swatches(swatches)
  rescue VibrantPalette::Error
    procedural_from_path(image_path)
  rescue StandardError
    :not_implemented
  end

  def extract_from_rgb(red, green, blue)
    lightness, a_axis, b_axis = rgb_to_lab(red, green, blue)

    {
      hue_family: hue_family_for_rgb(red, green, blue),
      centroid: { l: lightness.round(2), a: a_axis.round(2), b: b_axis.round(2) },
      swatches: [
        {
          hex: rgb_to_hex(red, green, blue),
          population: 1.0,
          lab: { l: lightness, a: a_axis, b: b_axis }
        }
      ],
      extracted_at: Time.now.utc.iso8601
    }
  end

  private

  def from_swatches(swatches)
    total = swatches.sum(&:population).to_f
    total = 1.0 if total <= 0

    lab_swatches = swatches.map do |swatch|
      l, a, b = rgb_to_lab(swatch.r, swatch.g, swatch.b)
      {
        hex: rgb_to_hex(swatch.r, swatch.g, swatch.b),
        population: (swatch.population / total).round(4),
        lab: { l: l, a: a, b: b },
        rgb: { r: swatch.r, g: swatch.g, b: swatch.b }
      }
    end

    centroid = weighted_centroid(lab_swatches)
    dominant = swatches.max_by(&:population)

    {
      hue_family: hue_family_for_rgb(dominant.r, dominant.g, dominant.b),
      centroid: {
        l: centroid[0].round(2),
        a: centroid[1].round(2),
        b: centroid[2].round(2)
      },
      swatches: lab_swatches.map { |entry| entry.slice(:hex, :population, :lab) },
      extracted_at: Time.now.utc.iso8601
    }
  end

  def weighted_centroid(lab_swatches)
    lab_swatches.reduce([0.0, 0.0, 0.0]) do |(l, a, b), entry|
      weight = entry[:population]
      [
        l + entry[:lab][:l] * weight,
        a + entry[:lab][:a] * weight,
        b + entry[:lab][:b] * weight
      ]
    end
  end

  def procedural_from_path(image_path)
    bytes = File.binread(image_path)
    return :not_implemented if bytes.bytesize < 64

    # Fallback when libvips is unavailable: sample PNG payload bytes for a
    # deterministic average colour so seeds/rake still work in constrained envs.
    sample = bytes.bytes.each_slice(3).first(200).map { |chunk| chunk.sum / chunk.size }
    r = sample[0..63].sum / 64
    g = sample[64..127].sum / 64
    b = sample[128..191].sum / 64
    extract_from_rgb(r.clamp(0, 255), g.clamp(0, 255), b.clamp(0, 255))
  end

  def rgb_to_lab(r, g, b)
    rn = pivot(r / 255.0)
    gn = pivot(g / 255.0)
    bn = pivot(b / 255.0)

    x = (rn * 0.4124 + gn * 0.3576 + bn * 0.1805) / 0.95047
    y = (rn * 0.2126 + gn * 0.7152 + bn * 0.0722) / 1.00000
    z = (rn * 0.0193 + gn * 0.1192 + bn * 0.9505) / 1.08883

    fx = pivot_lab(x)
    fy = pivot_lab(y)
    fz = pivot_lab(z)

    l = (116 * fy) - 16
    a = 500 * (fx - fy)
    b_val = 200 * (fy - fz)
    [l, a, b_val]
  end

  def pivot(value)
    value > 0.04045 ? ((value + 0.055) / 1.055)**2.4 : value / 12.92
  end

  def pivot_lab(value)
    value > 0.008856 ? value**(1.0 / 3) : (7.787 * value) + (16.0 / 116)
  end

  def hue_family_for_rgb(red, green, blue)
    hue, saturation, value = rgb_to_hsv(red, green, blue)
    return "neutral" if saturation < NEUTRAL_SATURATION || value < NEUTRAL_VALUE

    HUE_FAMILIES.each do |range, family|
      return family if range.cover?(hue.round)
    end
    "neutral"
  end

  def rgb_to_hsv(red, green, blue)
    r = red / 255.0
    g = green / 255.0
    b = blue / 255.0
    max = [r, g, b].max
    min = [r, g, b].min
    delta = max - min

    hue =
      if delta.zero?
        0.0
      elsif max == r
        60 * (((g - b) / delta) % 6)
      elsif max == g
        60 * (((b - r) / delta) + 2)
      else
        60 * (((r - g) / delta) + 4)
      end
    hue += 360 if hue.negative?

    saturation = max.zero? ? 0.0 : delta / max
    [hue, saturation, max]
  end

  def rgb_to_hex(*channels)
    format("#%02x%02x%02x", *channels.map { |channel| Integer(channel.round).clamp(0, 255) })
  end
end
