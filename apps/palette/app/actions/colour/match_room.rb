# frozen_string_literal: true

require "securerandom"
require_relative "../../../slices/colour/contracts/match_room"

module AppsPalette
  module Actions
    module Colour
      class MatchRoom < AppsPalette::Action
        DEFAULT_LIMIT = 12

        def handle(request, response)
          uploaded = uploaded_image(request)
          result = AppsPalette::Contracts::Colour::MatchRoom.new.call(image: uploaded)

          unless result.success?
            return error_response(response, 422, "validation_error", result.errors.to_h)
          end

          path = UploadedImage.persist(uploaded, prefix: "match-room")
          begin
            palette = PaletteExtractor.new.extract(path)
            if palette == :not_implemented
              return error_response(response, 422, "extract_failed", { message: "Could not extract a palette from that image" })
            end

            lab = palette.fetch(:centroid).values_at(:l, :a, :b)
            started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
            matches = ColourMatcher.new.match_lab(lab, limit: DEFAULT_LIMIT)
            elapsed_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round

            response.status = 200
            response.format = :json
            response.body = {
              artworks: matches,
              palette: {
                hue_family: palette[:hue_family],
                centroid: palette[:centroid],
                swatches: palette[:swatches]
              },
              meta: {
                count: matches.size,
                query_ms: elapsed_ms
              }
            }.to_json
          ensure
            File.delete(path) if path && File.exist?(path)
          end
        end

        private

        def uploaded_image(request)
          params = request.params
          UploadedImage.normalise(params[:image] || params["image"])
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
