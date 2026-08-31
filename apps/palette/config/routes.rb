# frozen_string_literal: true

module AppsPalette
  class Routes < Hanami::Routes
    get "/health", to: "health.show"
    post "/colour/extract", to: "colour.extract"
    get "/colour/similar/:artwork_id", to: "colour.similar"
    post "/colour/match-room", to: "colour.match_room"
  end
end
