# frozen_string_literal: true

class Cart < ApplicationRecord
  has_many :cart_items, dependent: :destroy
  has_many :artworks, through: :cart_items

  validates :session_id, presence: true, uniqueness: true

  def total_items
    cart_items.sum(:quantity)
  end

  def subtotal_cents
    cart_items.includes(:artwork).sum { |item| item.artwork.price_cents * item.quantity }
  end

  def framing_total_cents
    cart_items.sum { |item| item.framing? ? Artwork::FRAMING_PRICE_CENTS * item.quantity : 0 }
  end

  def total_cents
    subtotal_cents + framing_total_cents
  end
end
