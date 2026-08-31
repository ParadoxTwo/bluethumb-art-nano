# frozen_string_literal: true

class CartsController < ApplicationController
  def show
    @cart_items = current_cart.cart_items.includes(artwork: [:artist, { image_attachment: :blob }])
  end
end
