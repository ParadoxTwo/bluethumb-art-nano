# frozen_string_literal: true

module AppsPalette
  module Contracts
    module Colour
      class Extract < Dry::Validation::Contract
        params do
          required(:artwork_id).filled(:integer)
          optional(:force).maybe(:bool)
        end
      end
    end
  end
end
