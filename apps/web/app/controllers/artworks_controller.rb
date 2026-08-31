# frozen_string_literal: true

class ArtworksController < ApplicationController
  rescue_from Artworks::FacetParser::InvalidFacetError, with: :not_found

  SIMILAR_LIMIT = 6
  RELATED_LIMIT = 4

  def index
    segments = params[:facets].to_s.split("/")
    segments += ["q", params[:q]] if params[:q].present?
    @facets = Artworks::FacetParser.parse(segments)
    @sort = @facets["sort"] || "newest"
    scope = Artworks::FacetQuery.new(@facets).call
    @pagy, @artworks = pagy(scope, limit: 24)
    @total_count = @pagy.count

    if turbo_frame_request?
      render partial: "results_frame",
             locals: { artworks: @artworks, pagy: @pagy, total_count: @total_count, facets: @facets, sort: @sort },
             layout: false
    end
  end

  def show
    @artwork = Artwork.includes(:artist, image_attachment: :blob, gallery_images_attachments: :blob).find_by!(slug: params[:slug])
    @related_artworks = Artwork.same_style_as(@artwork).includes(:artist, image_attachment: :blob).limit(RELATED_LIMIT)
    @similar_by_colour = begin
      colour_neighbours(@artwork)
    rescue PaletteClient::Error
      # The static rail is a nicety; a palette service outage must not take
      # the artwork page down with it.
      Artwork.none
    end
    @cart_item = current_cart.cart_items.find_by(artwork: @artwork)
  end

  # JSON feed for the ColourPicker island. The browser talks to Rails, Rails
  # talks to the palette service: colour ranking stays in Hanami, presentation
  # stays here.
  def colour_matches
    artwork = Artwork.find_by(slug: params[:slug])
    return render_colour_error("not_found", "Artwork not found", :not_found) unless artwork

    hex = normalised_hex(params[:hex])
    if params[:hex].present? && hex.nil?
      return render_colour_error("invalid_colour", "Expected a 6-digit hex colour", :unprocessable_content)
    end

    artworks = colour_neighbours(artwork, hex: hex)

    render json: {
      artworks: artworks.map { |match| colour_match_json(match) },
      meta: { seed: hex, count: artworks.size }
    }
  rescue PaletteClient::Error => e
    render_colour_error("palette_unavailable", e.message, :service_unavailable)
  end

  private

  def colour_neighbours(artwork, hex: nil)
    return Artwork.none if hex.nil? && artwork.palette_centroid_l.nil?

    response = PaletteClient.new.similar(artwork.id, hex: hex)
    ids = Array(response["artworks"]).map { |entry| entry["id"] || entry["artwork_id"] }.compact
    return Artwork.none if ids.empty?

    Artwork.available.where(id: ids).includes(:artist, image_attachment: :blob).in_order_of(:id, ids).limit(SIMILAR_LIMIT)
  end

  def colour_match_json(artwork)
    {
      id: artwork.id,
      title: artwork.title,
      artist: artwork.artist.name,
      price: helpers.format_price(artwork.price_cents),
      url: artwork_path(artwork),
      image_url: artwork.image.attached? ? url_for(artwork.image) : nil
    }
  end

  def normalised_hex(value)
    match = /\A#?(\h{6})\z/.match(value.to_s)
    match && "##{match[1].downcase}"
  end

  def render_colour_error(code, message, status)
    render json: { error: { code: code, message: message } }, status: status
  end

  def not_found
    render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
  end
end
