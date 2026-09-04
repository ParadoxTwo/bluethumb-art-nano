# frozen_string_literal: true

module PaletteWebmock
  def stub_palette_similar(source_id, returning:, hex: nil)
    artworks = Array(returning).map do |entry|
      entry.is_a?(Hash) ? entry : { id: entry.id, distance: 0.1 }
    end

    request = stub_request(:get, "http://localhost:9292/colour/similar/#{source_id}")
    request = request.with(query: { "hex" => hex.to_s.delete_prefix("#") }) if hex

    request
      .to_return(
        status: 200,
        body: { artworks: artworks }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def stub_palette_extract(artwork_id)
    stub_request(:post, "http://localhost:9292/colour/extract")
      .with(body: hash_including("artwork_id" => artwork_id))
      .to_return(
        status: 200,
        body: { status: "ok" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def stub_palette_match_room(returning:, palette: {})
    artworks = Array(returning).map do |entry|
      entry.is_a?(Hash) ? entry : { id: entry.id, distance: 0.1 }
    end

    stub_request(:post, "http://localhost:9292/colour/match-room")
      .to_return(
        status: 200,
        body: {
          artworks: artworks,
          palette: palette,
          meta: { count: artworks.size, query_ms: 1 }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def stub_palette_unavailable
    stub_request(:any, %r{http://localhost:9292/}).to_raise(Errno::ECONNREFUSED)
  end
end

RSpec.configure do |config|
  config.include PaletteWebmock
end
