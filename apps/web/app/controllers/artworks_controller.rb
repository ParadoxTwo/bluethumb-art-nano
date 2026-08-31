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
    @similar_by_colour = similar_by_colour(@artwork)
    @cart_item = current_cart.cart_items.find_by(artwork: @artwork)
  end

  private

  def similar_by_colour(artwork)
    return Artwork.none unless artwork.palette_centroid_l

    response = PaletteClient.new.similar(artwork.id)
    ids = Array(response["artworks"]).map { |entry| entry["id"] || entry["artwork_id"] }.compact
    return Artwork.none if ids.empty?

    Artwork.available.where(id: ids).includes(:artist, image_attachment: :blob).in_order_of(:id, ids).limit(SIMILAR_LIMIT)
  rescue PaletteClient::Error
    Artwork.none
  end

  def not_found
    render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
  end
end
