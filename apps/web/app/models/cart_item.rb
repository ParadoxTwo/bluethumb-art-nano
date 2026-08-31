# frozen_string_literal: true

class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :artwork

  validates :quantity, numericality: { greater_than: 0, only_integer: true }
  validates :artwork_id, uniqueness: { scope: %i[cart_id framing_option] }
  validates :framing_option, inclusion: { in: Artwork::FRAMING_OPTIONS, allow_nil: true }

  def framing?
    framing_option.present?
  end

  def line_total_cents
    base = artwork.price_cents * quantity
    framing = framing? ? Artwork::FRAMING_PRICE_CENTS * quantity : 0
    base + framing
  end
end
