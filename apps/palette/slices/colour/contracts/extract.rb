# frozen_string_literal: true

require "dry/validation"
require_relative "match_room"

module AppsPalette
  module Contracts
    module Colour
      class Extract < Dry::Validation::Contract
        params do
          required(:artwork_id).filled(:integer)
          optional(:force).maybe(:bool)
          optional(:image)
        end

        # An image may be sent instead of relying on the artwork's file being
        # readable from this service's own disk. Same limits as a room upload,
        # so there is one answer to "what will this service accept".
        rule(:image) do
          next if value.nil?

          tempfile = value[:tempfile] || value["tempfile"] if value.respond_to?(:[])
          unless tempfile
            next key.failure("must be an uploaded image")
          end

          type = value[:type] || value["type"]
          size = value[:size] || value["size"] || (tempfile.respond_to?(:size) ? tempfile.size : nil)

          key.failure("invalid mime type") if type && !MatchRoom::ALLOWED_TYPES.include?(type)
          key.failure("file too large (max 8MB)") if size && size.to_i > MatchRoom::MAX_BYTES
        end
      end
    end
  end
end
