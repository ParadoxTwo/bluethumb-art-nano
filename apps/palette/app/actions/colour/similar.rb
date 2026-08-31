# frozen_string_literal: true

module AppsPalette
  module Actions
    module Colour
      class Similar < AppsPalette::Action
        def handle(request, response)
          artwork_id = request.params[:artwork_id].to_i
          started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          results = ColourMatcher.new.similar_artworks(artwork_id)
          elapsed_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round

          response.status = 200
          response.format = :json
          response.body = {
            artworks: results,
            meta: { count: results.size, query_ms: elapsed_ms }
          }.to_json
        end
      end
    end
  end
end
