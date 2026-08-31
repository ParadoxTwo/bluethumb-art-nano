# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_08_29_100001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "artists", force: :cascade do |t|
    t.text "bio"
    t.datetime "created_at", null: false
    t.string "location"
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_artists_on_slug", unique: true
  end

  create_table "artworks", force: :cascade do |t|
    t.bigint "artist_id", null: false
    t.datetime "created_at", null: false
    t.integer "depth_cm"
    t.text "description"
    t.datetime "featured_at"
    t.jsonb "generation_seed", default: {}, null: false
    t.integer "height_cm"
    t.string "medium", null: false
    t.string "orientation", null: false
    t.float "palette_centroid_a"
    t.float "palette_centroid_b"
    t.float "palette_centroid_l"
    t.jsonb "palette_data"
    t.datetime "palette_extracted_at"
    t.integer "popularity_score", default: 0, null: false
    t.integer "price_cents", null: false
    t.string "slug", null: false
    t.string "status", default: "available", null: false
    t.string "style", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.decimal "weight_kg", precision: 6, scale: 2
    t.integer "width_cm"
    t.index ["artist_id"], name: "index_artworks_on_artist_id"
    t.index ["featured_at"], name: "index_artworks_on_featured_at", where: "(featured_at IS NOT NULL)"
    t.index ["popularity_score"], name: "index_artworks_on_popularity_score"
    t.index ["slug"], name: "index_artworks_on_slug", unique: true
    t.index ["status", "price_cents"], name: "index_artworks_on_status_and_price_cents"
    t.index ["style", "medium", "price_cents"], name: "index_artworks_facets_available", where: "((status)::text = 'available'::text)"
  end

  create_table "cart_items", force: :cascade do |t|
    t.bigint "artwork_id", null: false
    t.bigint "cart_id", null: false
    t.datetime "created_at", null: false
    t.string "framing_option"
    t.integer "quantity", default: 1, null: false
    t.datetime "updated_at", null: false
    t.index "cart_id, artwork_id, COALESCE(framing_option, ''::character varying)", name: "index_cart_items_on_cart_artwork_framing", unique: true
    t.index ["artwork_id"], name: "index_cart_items_on_artwork_id"
    t.index ["cart_id"], name: "index_cart_items_on_cart_id"
  end

  create_table "carts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "session_id", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_carts_on_session_id", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "artworks", "artists"
  add_foreign_key "cart_items", "artworks"
  add_foreign_key "cart_items", "carts"
end
