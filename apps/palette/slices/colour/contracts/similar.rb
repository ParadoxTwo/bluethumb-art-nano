# frozen_string_literal: true

require "dry/validation"

module AppsPalette
  module Contracts
    module Colour
      class Similar < Dry::Validation::Contract
        params do
          required(:artwork_id).filled(:integer)
          optional(:hex).filled(:string, format?: /\A#?\h{6}\z/)
        end
      end
    end
  end
end
