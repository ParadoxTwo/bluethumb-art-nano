# frozen_string_literal: true

# Ranks artworks by perceptual colour distance.
#
# Distances are computed in CIELAB (not RGB) because RGB distance does not
# track how different two colours *look*: the same numeric gap is barely
# visible in dark greens and glaring in light blues.
#
# Known failure mode: a palette centroid is an average, so a canvas that is
# half crimson and half white averages to pink and will not rank next to a
# wholly crimson one. Centroid ranking answers "what is the overall cast of
# this work", not "which works contain this exact colour".
class ColourMatcher
  DEFAULT_LIMIT = 12
  HEX_PATTERN = /\A#?(\h{2})(\h{2})(\h{2})\z/

  class InvalidHexError < ArgumentError; end

  def delta_e76(lab_a, lab_b)
    l1, a1, b1 = lab_a
    l2, a2, b2 = lab_b
    Math.sqrt((l2 - l1)**2 + (a2 - a1)**2 + (b2 - b1)**2)
  end

  # Converts a CSS hex colour to a CIELAB triple. Delegates the actual
  # conversion to PaletteExtractor so there is exactly one RGB->LAB
  # implementation in the service and the two cannot drift apart.
  def lab_for_hex(hex)
    match = HEX_PATTERN.match(hex.to_s)
    raise InvalidHexError, "expected a 6-digit hex colour, got #{hex.inspect}" unless match

    rgb = match.captures.map { |pair| pair.to_i(16) }
    PaletteExtractor.new.extract_from_rgb(*rgb).fetch(:centroid).values_at(:l, :a, :b)
  end

  # Pure ranking step: candidates in, ordered {id:, distance:} out. Kept free
  # of the database so ranking can be specced against fixture palettes.
  # Ties break on id so the same query always returns the same order.
  def rank(candidates, lab, limit: DEFAULT_LIMIT)
    candidates
      .reject { |candidate| [candidate[:l], candidate[:a], candidate[:b]].any?(&:nil?) }
      .map do |candidate|
        {
          id: candidate[:id],
          distance: delta_e76(lab, [candidate[:l], candidate[:a], candidate[:b]]).round(3)
        }
      end
      .sort_by { |entry| [entry[:distance], entry[:id]] }
      .first(limit)
  end

  # seed_lab ranks against an arbitrary colour (a swatch the buyer picked);
  # without it the artwork's own palette centroid is the seed.
  def similar_artworks(artwork_id, limit: DEFAULT_LIMIT, seed_lab: nil)
    lab = seed_lab || centroid_for(artwork_id)
    return [] if lab.nil? || lab.any?(&:nil?)

    rank(fetch_candidates(exclude_id: artwork_id), lab, limit: limit)
  end

  # Rank the whole available catalogue against a room (or any) palette centroid.
  def match_lab(lab, limit: DEFAULT_LIMIT)
    return [] if lab.nil? || lab.any?(&:nil?)

    rank(fetch_candidates, lab, limit: limit)
  end

  private

  def connection
    PG.connect(ENV.fetch("DATABASE_URL"))
  end

  def centroid_for(artwork_id)
    row = connection.exec_params(
      "SELECT palette_centroid_l, palette_centroid_a, palette_centroid_b FROM artworks WHERE id = $1",
      [artwork_id]
    ).first
    return unless row

    [row["palette_centroid_l"]&.to_f, row["palette_centroid_a"]&.to_f, row["palette_centroid_b"]&.to_f]
  end

  def fetch_candidates(exclude_id: nil)
    sql = <<~SQL
      SELECT id, palette_centroid_l, palette_centroid_a, palette_centroid_b
      FROM artworks
      WHERE status = 'available'
        AND palette_centroid_l IS NOT NULL
    SQL
    params = []
    if exclude_id
      sql += " AND id != $1"
      params << exclude_id
    end

    connection.exec_params(sql, params).map do |row|
      {
        id: row["id"].to_i,
        l: row["palette_centroid_l"].to_f,
        a: row["palette_centroid_a"].to_f,
        b: row["palette_centroid_b"].to_f
      }
    end
  end
end
