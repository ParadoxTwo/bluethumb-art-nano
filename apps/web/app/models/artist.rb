# frozen_string_literal: true

class Artist < ApplicationRecord
  has_many :artworks, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, on: :create

  private

  def generate_slug
    return if slug.present?

    base = name.to_s.parameterize
    candidate = base
    suffix = 1

    while Artist.exists?(slug: candidate)
      candidate = "#{base}-#{suffix}"
      suffix += 1
    end

    self.slug = candidate
  end
end
