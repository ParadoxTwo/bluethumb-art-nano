# frozen_string_literal: true

class HomeController < ApplicationController
  STAFF_PICKS_LIMIT = 8

  def index
    @staff_picks = Artwork.featured.available.includes(:artist, image_attachment: :blob).limit(STAFF_PICKS_LIMIT)
    @staff_picks = Artwork.available.includes(:artist, image_attachment: :blob).order(created_at: :desc).limit(STAFF_PICKS_LIMIT) if @staff_picks.empty?
  end
end
