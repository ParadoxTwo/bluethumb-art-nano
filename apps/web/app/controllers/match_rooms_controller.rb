# frozen_string_literal: true

class MatchRoomsController < ApplicationController
  MATCH_LIMIT = 12

  def show
    # SSR shell: headline + how-it-works. The RoomMatch island handles upload.
  end

  def create
    upload = params[:image]
    unless upload.respond_to?(:tempfile) || upload.respond_to?(:path)
      return render json: { error: { code: "validation_error", message: "Choose a room photo to match" } },
                    status: :unprocessable_content
    end

    response = PaletteClient.new.match_room(upload)
    ids = Array(response["artworks"]).map { |entry| entry["id"] || entry["artwork_id"] }.compact
    artworks = if ids.empty?
      []
    else
      Artwork.available.where(id: ids).includes(:artist, image_attachment: :blob).in_order_of(:id, ids).limit(MATCH_LIMIT)
    end

    render json: {
      artworks: artworks.map { |artwork| match_json(artwork) },
      palette: response["palette"],
      meta: response["meta"] || { count: artworks.size }
    }
  rescue PaletteClient::Error => e
    render json: { error: { code: "palette_unavailable", message: e.message } }, status: :service_unavailable
  end

  private

  def match_json(artwork)
    {
      id: artwork.id,
      title: artwork.title,
      artist: artwork.artist.name,
      price: helpers.format_price(artwork.price_cents),
      url: artwork_path(artwork),
      image_url: artwork.image.attached? ? url_for(artwork.image) : nil
    }
  end
end
