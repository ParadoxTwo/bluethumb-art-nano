# frozen_string_literal: true

class CheckoutsController < ApplicationController
  before_action :ensure_cart_not_empty, only: %i[show create]

  def show
    @cart_items = current_cart.cart_items.includes(artwork: [:artist, { image_attachment: :blob }])
  end

  def create
    session[:last_order] = {
      "contact_email" => params[:contact_email],
      "contact_name" => params[:contact_name],
      "address_line1" => params[:address_line1],
      "address_city" => params[:address_city],
      "address_state" => params[:address_state],
      "address_postcode" => params[:address_postcode],
      "promo_code" => params[:promo_code],
      "total_cents" => current_cart.total_cents,
      "item_count" => current_cart.total_items,
      "placed_at" => Time.current.iso8601
    }

    current_cart.cart_items.destroy_all
    redirect_to checkout_thank_you_path
  end

  def thank_you
    @order = session[:last_order]
    redirect_to artworks_path, alert: "No recent order found." if @order.blank?
  end

  private

  def ensure_cart_not_empty
    return if current_cart.cart_items.any?

    redirect_to cart_path, alert: "Your cart is empty."
  end
end
