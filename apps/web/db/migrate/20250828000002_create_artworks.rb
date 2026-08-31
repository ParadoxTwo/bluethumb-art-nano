# frozen_string_literal: true

class CreateArtworks < ActiveRecord::Migration[8.1]
  def change
    create_table :artworks do |t|
      t.references :artist, null: false, foreign_key: true
      t.string :title, null: false
      t.string :slug, null: false
      t.text :description
      t.integer :width_cm
      t.integer :height_cm
      t.integer :depth_cm
      t.decimal :weight_kg, precision: 6, scale: 2
      t.string :medium, null: false
      t.string :style, null: false
      t.integer :price_cents, null: false
      t.string :status, null: false, default: "available"
      t.string :orientation, null: false
      t.jsonb :generation_seed, null: false, default: {}
      t.jsonb :palette_data
      t.datetime :palette_extracted_at
      t.float :palette_centroid_l
      t.float :palette_centroid_a
      t.float :palette_centroid_b

      t.timestamps
    end

    add_index :artworks, :slug, unique: true
    add_index :artworks, %i[style medium price_cents], where: "status = 'available'", name: "index_artworks_facets_available"
    add_index :artworks, %i[status price_cents]
  end
end
