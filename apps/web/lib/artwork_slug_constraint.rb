# frozen_string_literal: true

class ArtworkSlugConstraint
  def self.matches?(request)
    slug = request.params[:slug]
    slug.present? && !Artworks::FacetParser::FACET_KEYS.include?(slug)
  end
end
