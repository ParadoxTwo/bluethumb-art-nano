# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pagy::Method

  protect_from_forgery with: :exception

  before_action :set_current_cart

  helper_method :current_cart, :favourite_artwork_ids?, :favourite_artwork_ids

  private

  def current_cart
    @current_cart
  end

  def set_current_cart
    session[:cart_session_id] ||= SecureRandom.hex(16)
    @current_cart = Cart.find_or_create_by!(session_id: session[:cart_session_id].to_s)
  end

  def favourite_artwork_ids
    Array(session[:favourite_artwork_ids]).map(&:to_i)
  end

  def favourite_artwork_ids?(artwork_id)
    favourite_artwork_ids.include?(artwork_id.to_i)
  end
end
