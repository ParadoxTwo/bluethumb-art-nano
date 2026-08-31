# frozen_string_literal: true

require "hanami"
require_relative "../lib/colour_matcher"
require_relative "../lib/palette_extractor"

module AppsPalette
  class App < Hanami::App
    config.middleware.use :body_parser, :json
  end
end
