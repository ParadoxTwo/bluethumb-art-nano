# frozen_string_literal: true

class FavouritesController < ApplicationController
  def create
    artwork = Artwork.find(params[:artwork_id])
    ids = favourite_artwork_ids
    ids << artwork.id unless ids.include?(artwork.id)
    session[:favourite_artwork_ids] = ids.uniq

    redirect_back fallback_location: artwork_path(artwork), notice: "Saved to favourites"
  end

  def destroy
    artwork = Artwork.find(params[:artwork_id])
    session[:favourite_artwork_ids] = favourite_artwork_ids - [artwork.id]

    redirect_back fallback_location: artwork_path(artwork), notice: "Removed from favourites"
  end
end
