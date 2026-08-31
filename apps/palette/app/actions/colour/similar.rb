# frozen_string_literal: true

module AppsPalette
  module Actions
    module Colour
      class Similar < AppsPalette::Action
        # ?hex= lets a caller rank against a colour the buyer picked rather
        # than the artwork's own centroid. Without it, behaviour is unchanged.
        params do
          required(:artwork_id).filled(:integer)
          optional(:hex).filled(:string, format?: /\A#?\h{6}\z/)
        end

        def handle(request, response)
          unless request.params.valid?
            return error_response(response, 422, "validation_error", request.params.errors.to_h)
          end

          artwork_id = request.params[:artwork_id]
          hex = request.params[:hex]
          matcher = ColourMatcher.new
          seed_lab = hex ? matcher.lab_for_hex(hex) : nil

          started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          results = matcher.similar_artworks(artwork_id, seed_lab: seed_lab)
          elapsed_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round

          response.status = 200
          response.format = :json
          response.body = {
            artworks: results,
            meta: {
              count: results.size,
              query_ms: elapsed_ms,
              seed: seed_descriptor(artwork_id, hex, seed_lab)
            }
          }.to_json
        end

        private

        def seed_descriptor(artwork_id, hex, seed_lab)
          return { artwork_id: artwork_id } unless hex

          l, a, b = seed_lab
          { hex: "##{hex.delete_prefix('#').downcase}", lab: { l: l, a: a, b: b } }
        end

        def error_response(response, status, code, details)
          response.status = status
          response.format = :json
          response.body = { error: { code: code, message: "Invalid request", details: details } }.to_json
        end
      end
    end
  end
end
