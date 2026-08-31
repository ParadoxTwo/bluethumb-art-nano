# frozen_string_literal: true

class ArtistsController < ApplicationController
  def show
    @artist = Artist.find_by!(slug: params[:slug])
    @artworks = @artist.artworks.available.includes(:artist, image_attachment: :blob).order(created_at: :desc).limit(24)
  end
end
