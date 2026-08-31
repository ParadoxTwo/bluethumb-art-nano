# frozen_string_literal: true

require "database_cleaner/sequel"

# Clean the databases between tests tagged as `:db`
RSpec.configure do |config|
  # Returns all the configured databases across the app and its slices.
  #
  # Used in the before/after hooks below to ensure each database is cleaned between examples.
  #
  # Modify this proc (or any code below) if you only need specific databases cleaned.
  all_databases = -> {
    Hanami.app.with_slices.each_with_object([]) { |slice, dbs|
      begin
        next unless slice.key?("db.rom")

        dbs.concat slice["db.rom"].gateways.values.map(&:connection)
      rescue Hanami::ComponentLoadError, Sequel::DatabaseConnectionError
        # DB optional for palette stub specs
      end
    }.uniq
  }

  config.before :suite do
    all_databases.call.each do |db|
      DatabaseCleaner[:sequel, db: db].clean_with :truncation, except: ["schema_migrations"]
    end
  end

  config.prepend_before :each, :db do |example|
    strategy = example.metadata[:js] ? :truncation : :transaction

    all_databases.call.each do |db|
      DatabaseCleaner[:sequel, db: db].strategy = strategy
      DatabaseCleaner[:sequel, db: db].start
    end
  end

  config.after :each, :db do
    all_databases.call.each do |db|
      DatabaseCleaner[:sequel, db: db].clean
    end
  end
end
