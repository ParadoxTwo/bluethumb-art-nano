# frozen_string_literal: true

class ColourMatcher
  DEFAULT_LIMIT = 12

  def delta_e76(lab_a, lab_b)
    l1, a1, b1 = lab_a
    l2, a2, b2 = lab_b
    Math.sqrt((l2 - l1)**2 + (a2 - a1)**2 + (b2 - b1)**2)
  end

  def similar_artworks(artwork_id, limit: DEFAULT_LIMIT)
    source = fetch_artwork(artwork_id)
    return [] unless source

    lab = [source[:l], source[:a], source[:b]]
    return [] if lab.any?(&:nil?)

    candidates = fetch_candidates(artwork_id)
    ranked = candidates.map do |candidate|
      distance = delta_e76(lab, [candidate[:l], candidate[:a], candidate[:b]])
      { id: candidate[:id], distance: distance }
    end

    ranked.sort_by { |entry| entry[:distance] }.first(limit)
  end

  private

  def connection
    PG.connect(ENV.fetch("DATABASE_URL"))
  end

  def fetch_artwork(artwork_id)
    row = connection.exec_params(
      "SELECT id, palette_centroid_l, palette_centroid_a, palette_centroid_b FROM artworks WHERE id = $1",
      [artwork_id]
    ).first
    return unless row

    { id: row["id"].to_i, l: row["palette_centroid_l"]&.to_f, a: row["palette_centroid_a"]&.to_f, b: row["palette_centroid_b"]&.to_f }
  end

  def fetch_candidates(artwork_id)
    connection.exec_params(
      <<~SQL.squish,
        SELECT id, palette_centroid_l, palette_centroid_a, palette_centroid_b
        FROM artworks
        WHERE status = 'available'
          AND id != $1
          AND palette_centroid_l IS NOT NULL
      SQL
      [artwork_id]
    ).map do |row|
      {
        id: row["id"].to_i,
        l: row["palette_centroid_l"].to_f,
        a: row["palette_centroid_a"].to_f,
        b: row["palette_centroid_b"].to_f
      }
    end
  end
end
