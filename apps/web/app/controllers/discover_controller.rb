# frozen_string_literal: true

class DiscoverController < ApplicationController
  STEPS = {
    1 => :style,
    2 => :budget,
    3 => :size
  }.freeze

  BUDGET_RANGES = ArtworksHelper::PRICE_RANGES

  def show
    @step = (params[:step] || 1).to_i.clamp(1, 3)
    @quiz = session[:style_quiz] || {}
  end

  def update
    step = params[:step].to_i
    session[:style_quiz] = (session[:style_quiz] || {}).merge(quiz_params_for(step))

    if step < 3
      redirect_to discover_path(step: step + 1)
    else
      redirect_to browse_path_for(facets_from_quiz(session[:style_quiz]))
    end
  end

  private

  def quiz_params_for(step)
    case step
    when 1
      params.permit(:style).to_h.compact_blank
    when 2
      params.permit(:price).to_h.compact_blank
    when 3
      params.permit(:size).to_h.compact_blank
    else
      {}
    end
  end

  def facets_from_quiz(quiz)
    quiz.stringify_keys.slice("style", "price", "size")
  end

  def browse_path_for(facets)
    segments = facets.stringify_keys.flat_map { |key, value| [key, value] }
    segments.any? ? artworks_path(facets: segments.join("/")) : artworks_path
  end
end
