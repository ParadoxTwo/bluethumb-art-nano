# frozen_string_literal: true

require_relative "../../../slices/colour/contracts/similar"

module AppsPalette
  module Actions
    module Colour
      class Similar < AppsPalette::Action
        # ?hex= lets a caller rank against a colour the buyer picked rather
        # than the artwork's own centroid. Without it, behaviour is unchanged.
        def handle(request, response)
          result = AppsPalette::Contracts::Colour::Similar.new.call(similar_params(request))

          unless result.success?
            return error_response(response, 422, "validation_error", result.errors.to_h)
          end

          artwork_id = result[:artwork_id]
          hex = result[:hex]
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

        def similar_params(request)
          raw = request.params.to_h
          {
            artwork_id: raw[:artwork_id] || raw["artwork_id"],
            hex: raw[:hex] || raw["hex"]
          }.compact
        end

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
