# frozen_string_literal: true

class Artwork < ApplicationRecord
  include PgSearch::Model

  MEDIUMS = %w[oil acrylic watercolor mixed-media digital photography].freeze
  STYLES = %w[abstract landscape portrait figurative minimalism surrealism].freeze
  STATUSES = %w[available sold].freeze
  ORIENTATIONS = %w[portrait landscape square].freeze
  HUE_FAMILIES = %w[red orange yellow green blue purple neutral].freeze
  FRAMING_OPTIONS = %w[natural black white].freeze
  FRAMING_PRICE_CENTS = 25_000
  MAX_SWATCHES = 6

  belongs_to :artist
  has_one_attached :image
  has_many_attached :gallery_images
  has_many :cart_items, dependent: :destroy

  pg_search_scope :search_by_text,
                  against: %i[title description],
                  associated_against: { artist: :name },
                  using: { tsearch: { prefix: true } }

  validates :title, :slug, :medium, :style, :price_cents, :status, :orientation, presence: true
  validates :slug, uniqueness: true
  validates :medium, inclusion: { in: MEDIUMS }
  validates :style, inclusion: { in: STYLES }
  validates :status, inclusion: { in: STATUSES }
  validates :orientation, inclusion: { in: ORIENTATIONS }
  validates :price_cents, numericality: { greater_than: 0 }

  before_validation :generate_slug, on: :create

  scope :available, -> { where(status: "available") }
  scope :featured, -> { where.not(featured_at: nil).order(featured_at: :desc) }
  scope :by_style, ->(style) { where(style: style) }
  scope :by_medium, ->(medium) { where(medium: medium) }
  scope :by_orientation, ->(orientation) { where(orientation: orientation) }
  scope :by_price_range, lambda { |range|
    where(price_cents: (range.begin * 100)..(range.end * 100))
  }
  scope :by_hue_family, lambda { |hue|
    where("palette_data ->> 'hue_family' = ?", hue)
  }
  scope :by_size_band, lambda { |band|
    range = Artworks::FacetQuery::SIZE_BANDS.fetch(band)
    where("GREATEST(width_cm, height_cm) >= ? AND GREATEST(width_cm, height_cm) <= ?", range.begin, range.end)
  }
  scope :same_style_as, ->(artwork) { available.where(style: artwork.style).where.not(id: artwork.id) }

  def price_aud
    price_cents / 100.0
  end

  def available?
    status == "available"
  end

  def sold?
    status == "sold"
  end

  def featured?
    featured_at.present?
  end

  def dimensions_label
    parts = [width_cm, height_cm].compact
    return "Dimensions unavailable" if parts.empty?

    label = parts.join(" × ")
    label += " cm" unless label.include?("cm")
    label
  end

  # Swatches the palette service extracted, normalised for display. Anything
  # malformed is dropped rather than rendered, so a half-written palette can
  # never break the artwork page.
  def palette_swatches(limit: MAX_SWATCHES)
    raw = palette_data.is_a?(Hash) ? palette_data["swatches"] : nil

    Array(raw).filter_map do |swatch|
      next unless swatch.is_a?(Hash)

      hex = swatch["hex"].to_s.downcase
      next unless hex.match?(/\A#\h{6}\z/)

      { "hex" => hex, "population" => swatch["population"].to_f }
    end.first(limit)
  end

  def to_param
    slug
  end

  private

  def generate_slug
    return if slug.present?

    base = title.to_s.parameterize
    candidate = base
    suffix = 1

    while Artwork.exists?(slug: candidate)
      candidate = "#{base}-#{suffix}"
      suffix += 1
    end

    self.slug = candidate
  end
end
