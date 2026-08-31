# frozen_string_literal: true

require "capybara/rspec"

Capybara.app = Rails.application
Capybara.default_driver = :rack_test

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :rack_test
  end
end
