# frozen_string_literal: true

class CartItemsUniqueByFraming < ActiveRecord::Migration[8.1]
  def change
    remove_index :cart_items, column: %i[cart_id artwork_id], unique: true
    add_index :cart_items,
              "cart_id, artwork_id, COALESCE(framing_option, '')",
              unique: true,
              name: "index_cart_items_on_cart_artwork_framing"
  end
end
