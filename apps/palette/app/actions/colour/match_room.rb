# frozen_string_literal: true

module AppsPalette
  module Actions
    module Colour
      class MatchRoom < AppsPalette::Action
        def handle(_request, response)
          response.status = 501
          response.format = :json
          response.body = {
            error: {
              code: "not_implemented",
              message: "Room match is a Phase 1 stub"
            }
          }.to_json
        end
      end
    end
  end
end
