# frozen_string_literal: true

class CreateArtists < ActiveRecord::Migration[8.1]
  def change
    create_table :artists do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :bio
      t.string :location

      t.timestamps
    end

    add_index :artists, :slug, unique: true
  end
end
