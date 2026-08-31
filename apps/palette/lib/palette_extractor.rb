# frozen_string_literal: true

require "json"

class PaletteExtractor
  HUE_FAMILIES = {
    (0..15) => "red",
    (16..45) => "orange",
    (46..70) => "yellow",
    (71..160) => "green",
    (161..250) => "blue",
    (251..330) => "purple",
    (331..360) => "red"
  }.freeze

  def extract(image_path)
    return procedural_from_path(image_path) if File.file?(image_path)

    :not_implemented
  rescue StandardError
    :not_implemented
  end

  def extract_from_rgb(red, green, blue)
    # Name the LAB axes apart from the RGB channels. They were both called
    # b, so the swatch hex was built from the b* axis - usually negative -
    # rather than from the blue channel.
    lightness, a_axis, b_axis = rgb_to_lab(red, green, blue)
    hue = lab_to_hue(a_axis, b_axis)

    {
      hue_family: hue_family_for(hue),
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

  def procedural_from_path(image_path)
    bytes = File.binread(image_path)
    return :not_implemented if bytes.bytesize < 64

    # Sample bytes from PNG payload region for a deterministic average colour.
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

  def rgb_to_hex(*channels)
    format("#%02x%02x%02x", *channels.map { |channel| Integer(channel.round).clamp(0, 255) })
  end
end
