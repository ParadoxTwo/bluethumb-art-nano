# frozen_string_literal: true

class Phase2MarketplaceFields < ActiveRecord::Migration[8.1]
  def change
    change_table :artworks, bulk: true do |t|
      t.datetime :featured_at
      t.integer :popularity_score, default: 0, null: false
    end

    add_index :artworks, :featured_at, where: "featured_at IS NOT NULL"
    add_index :artworks, :popularity_score

    add_column :cart_items, :framing_option, :string
  end
end
