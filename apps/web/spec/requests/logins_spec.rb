# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Login", type: :request do
  describe "GET /login" do
    it "renders the sign-in stub page" do
      get login_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("sign in coming soon")
      expect(response.body).to include("Browse artworks")
    end
  end
end
