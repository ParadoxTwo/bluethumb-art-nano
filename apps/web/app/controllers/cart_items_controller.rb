# frozen_string_literal: true

class CartItemsController < ApplicationController
  def create
    artwork = Artwork.available.find(params[:artwork_id])
    framing_option = params[:framing_option].presence
    item = current_cart.cart_items.find_or_initialize_by(artwork: artwork, framing_option: framing_option)

    item.quantity = item.persisted? ? item.quantity + 1 : 1
    item.save!

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: artworks_path, notice: "Added to cart" }
    end
  end

  def update
    item = current_cart.cart_items.find(params[:id])
    if params[:framing_option].present?
      item.update!(framing_option: params[:framing_option])
    end

    redirect_back fallback_location: cart_path, notice: "Cart updated"
  end

  def destroy
    item = current_cart.cart_items.find(params[:id])
    item.destroy!

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: cart_path, notice: "Removed from cart" }
    end
  end
end
