# frozen_string_literal: true

class PaletteDataBuilder
  HUE_FAMILIES = {
    (0..15) => "red",
    (16..45) => "orange",
    (46..70) => "yellow",
    (71..160) => "green",
    (161..250) => "blue",
    (251..330) => "purple",
    (331..360) => "red"
  }.freeze

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
    hue = lab_to_hue(a, b)
    hue_family = hue_family_for(hue)

    {
      l: l.round(2),
      a: a.round(2),
      b: b.round(2),
      data: {
        "hue_family" => hue_family,
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

  def lab_to_hue(a, b)
    hue = Math.atan2(b, a) * 180 / Math::PI
    hue += 360 if hue.negative?
    hue
  end

  def hue_family_for(hue)
    HUE_FAMILIES.each do |range, family|
      return family if range.cover?(hue.round)
    end
    "neutral"
  end
end
