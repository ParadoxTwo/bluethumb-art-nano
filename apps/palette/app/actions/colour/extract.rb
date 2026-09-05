# frozen_string_literal: true

require_relative "../../../slices/colour/contracts/extract"

module AppsPalette
  module Actions
    module Colour
      class Extract < AppsPalette::Action
        def handle(request, response)
          raw = request.params.to_h
          uploaded = UploadedImage.normalise(raw[:image] || raw["image"])
          result = AppsPalette::Contracts::Colour::Extract.new.call(extract_params(raw, uploaded))

          unless result.success?
            return error_response(response, 422, "validation_error", result.errors.to_h)
          end

          artwork_id = result[:artwork_id]
          image_path, temporary = source_image(artwork_id, uploaded)

          unless image_path
            return error_response(response, 404, "not_found", { artwork_id: artwork_id })
          end

          begin
            palette = PaletteExtractor.new.extract(image_path)
            if palette == :not_implemented
              return not_implemented_response(response, artwork_id)
            end

            persist_palette!(artwork_id, palette)

            response.status = 200
            response.format = :json
            response.body = {
              artwork_id: artwork_id,
              source: temporary ? "upload" : "disk",
              palette: palette
            }.to_json
          ensure
            File.delete(image_path) if temporary && File.exist?(image_path)
          end
        end

        private

        # Callers that share a disk with this service can just name the
        # artwork; callers that do not - Rails on Render, where each service
        # gets its own filesystem - send the bytes instead.
        def source_image(artwork_id, uploaded)
          return [UploadedImage.persist(uploaded, prefix: "extract"), true] if uploaded

          [image_path_for(artwork_id), false]
        end

        def extract_params(raw, uploaded)
          params = {
            artwork_id: raw[:artwork_id] || raw["artwork_id"],
            force: raw.key?(:force) || raw.key?("force") ? (raw[:force] || raw["force"]) : nil
          }
          params[:image] = uploaded if uploaded
          params
        end

        def connection
          PG.connect(ENV.fetch("DATABASE_URL"))
        end

        def image_path_for(artwork_id)
          row = connection.exec_params(
            "SELECT active_storage_blobs.key FROM active_storage_attachments " \
            "JOIN active_storage_blobs ON active_storage_blobs.id = active_storage_attachments.blob_id " \
            "WHERE active_storage_attachments.record_type = 'Artwork' " \
            "AND active_storage_attachments.record_id = $1 " \
            "AND active_storage_attachments.name = 'image' LIMIT 1",
            [artwork_id]
          ).first
          return unless row

          storage_root = ENV.fetch("ACTIVE_STORAGE_ROOT", File.expand_path("../../../../web/storage", __dir__))
          Dir.glob(File.join(storage_root, "**", row["key"])).first
        end

        def persist_palette!(artwork_id, palette)
          connection.exec_params(
            "UPDATE artworks SET palette_data = $2::jsonb, palette_centroid_l = $3, " \
            "palette_centroid_a = $4, palette_centroid_b = $5, palette_extracted_at = NOW() WHERE id = $1",
            [
              artwork_id,
              palette.to_json,
              palette.dig(:centroid, :l),
              palette.dig(:centroid, :a),
              palette.dig(:centroid, :b)
            ]
          )
        end

        def not_implemented_response(response, artwork_id)
          response.status = 501
          response.format = :json
          response.body = {
            error: {
              code: "not_implemented",
              message: "Palette extraction unavailable for this image"
            },
            artwork_id: artwork_id
          }.to_json
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
