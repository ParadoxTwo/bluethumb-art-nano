# frozen_string_literal: true

module AppsPalette
  module Actions
    module Health
      class Show < AppsPalette::Action
        def handle(_request, response)
          response.status = 200
          response.format = :json
          response.body = { status: "ok" }.to_json
        end
      end
    end
  end
end
