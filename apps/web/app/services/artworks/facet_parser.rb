# frozen_string_literal: true

module Artworks
  class FacetParser
    FACET_KEYS = %w[style medium price orientation colour sort size q].freeze
    SORT_VALUES = %w[newest price-asc price-desc popular].freeze
    SIZE_VALUES = %w[small medium large].freeze
    RESERVED_SLUGS = FACET_KEYS.freeze

    class InvalidFacetError < StandardError; end

    def self.parse(segments)
      new(segments).parse
    end

    def initialize(segments)
      @segments = Array(segments).compact_blank
    end

    def parse
      facets = {}
      i = 0

      while i < @segments.length
        key = @segments[i]
        value = @segments[i + 1]

        raise InvalidFacetError, "Unknown facet key: #{key}" unless FACET_KEYS.include?(key)
        raise InvalidFacetError, "Missing value for facet: #{key}" if value.blank?

        validate_value!(key, value)
        facets[key] = value
        i += 2
      end

      facets
    end

    def self.price_range(value)
      min_dollars, max_dollars = value.split("-", 2).map(&:to_i)
      raise InvalidFacetError, "Invalid price range: #{value}" if min_dollars.negative? || max_dollars <= min_dollars

      min_dollars..max_dollars
    end

    private

    def validate_value!(key, value)
      case key
      when "sort"
        raise InvalidFacetError, "Invalid sort: #{value}" unless SORT_VALUES.include?(value)
      when "size"
        raise InvalidFacetError, "Invalid size: #{value}" unless SIZE_VALUES.include?(value)
      end
    end
  end
end
