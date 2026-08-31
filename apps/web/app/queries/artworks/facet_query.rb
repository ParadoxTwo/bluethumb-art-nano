# frozen_string_literal: true

module Artworks
  class FacetQuery
    SIZE_BANDS = {
      "small" => 0...60,
      "medium" => 60..100,
      "large" => 101..999
    }.freeze

    def initialize(facets = {})
      @facets = facets.stringify_keys
      @sort = @facets.delete("sort") || "newest"
      @search_query = @facets.delete("q")
    end

    def call
      scope = Artwork.available.includes(:artist, image_attachment: :blob)
      scope = apply_search(scope) if @search_query.present?
      scope = apply_facets(scope)
      apply_sort(scope)
    end

    private

    def apply_facets(scope)
      @facets.each do |key, value|
        scope = apply_facet(scope, key, value)
      end
      scope
    end

    def apply_facet(scope, key, value)
      case key
      when "style"
        scope.by_style(value)
      when "medium"
        scope.by_medium(value)
      when "orientation"
        scope.by_orientation(value)
      when "colour"
        scope.by_hue_family(value)
      when "price"
        scope.by_price_range(FacetParser.price_range(value))
      when "size"
        scope.by_size_band(value)
      else
        scope
      end
    end

    def apply_search(scope)
      scope.search_by_text(@search_query)
    end

    def apply_sort(scope)
      case @sort
      when "price-asc"
        scope.order(price_cents: :asc, created_at: :desc)
      when "price-desc"
        scope.order(price_cents: :desc, created_at: :desc)
      when "popular"
        scope.order(popularity_score: :desc, created_at: :desc)
      else
        scope.order(created_at: :desc)
      end
    end
  end
end
