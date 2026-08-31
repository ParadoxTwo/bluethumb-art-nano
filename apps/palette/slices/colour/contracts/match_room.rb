# frozen_string_literal: true

module AppsPalette
  module Contracts
    module Colour
      class MatchRoom < Dry::Validation::Contract
        MAX_BYTES = 8 * 1024 * 1024
        ALLOWED_TYPES = %w[image/jpeg image/png image/webp].freeze

        params do
          required(:image).filled
        end

        rule(:image) do
          file = value
          next key.failure("must be uploaded") unless file.respond_to?(:[]) || file.is_a?(Hash)

          tempfile = file[:tempfile] || file["tempfile"]
          type = file[:type] || file["type"]
          size = file[:size] || file["size"] || (tempfile&.size)

          key.failure("invalid mime type") if type && !ALLOWED_TYPES.include?(type)
          key.failure("file too large (max 8MB)") if size && size.to_i > MAX_BYTES
        end
      end
    end
  end
end
