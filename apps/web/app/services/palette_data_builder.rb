# frozen_string_literal: true

class PaletteDataBuilder
  # Keep in lockstep with PaletteExtractor#hue_family_for_rgb — seeds must use
  # the same HSV buckets so browse facets match extracted palettes.
  HUE_FAMILIES = {
    (0..15) => "red",
    (16..45) => "orange",
    (46..70) => "yellow",
    (71..160) => "green",
    (161..250) => "blue",
    (251..330) => "purple",
    (331..360) => "red"
  }.freeze

  NEUTRAL_SATURATION = 0.12
  NEUTRAL_VALUE = 0.08

  def self.from_rgb(r, g, b)
    new(r, g, b).build
  end

  def initialize(r, g, b)
    @r = r
    @g = g
    @b = b
  end

  def build
    l, a, b = rgb_to_lab(@r, @g, @b)

    {
      l: l.round(2),
      a: a.round(2),
      b: b.round(2),
      data: {
        "hue_family" => hue_family_for_rgb(@r, @g, @b),
        "centroid" => { "l" => l.round(2), "a" => a.round(2), "b" => b.round(2) },
        "swatches" => [
          {
            "hex" => format("#%02x%02x%02x", @r, @g, @b),
            "population" => 1.0,
            "lab" => { "l" => l, "a" => a, "b" => b }
          }
        ]
      }
    }
  end

  private

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
end
