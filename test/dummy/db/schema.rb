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

ActiveRecord::Schema[8.1].define(version: 2026_10_16_120000) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "keystone_ui_pages_pages", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.json "document", null: false
    t.string "owner_type"
    t.integer "owner_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "undo_history"
    t.json "undone_changes"
    t.index ["owner_type", "owner_id", "slug"], name: "index_keystone_ui_pages_pages_on_owner_and_slug", unique: true
    t.index ["owner_type", "owner_id"], name: "index_keystone_ui_pages_pages_on_owner"
  end

  create_table "keystone_ui_pages_pdfs", force: :cascade do |t|
    t.integer "version_id", null: false
    t.string "values_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["version_id", "values_digest"], name: "index_keystone_ui_pages_pdfs_on_version_id_and_values_digest", unique: true
    t.index ["version_id"], name: "index_keystone_ui_pages_pdfs_on_version_id"
  end

  create_table "keystone_ui_pages_versions", force: :cascade do |t|
    t.integer "page_id", null: false
    t.integer "number", null: false
    t.json "document", null: false
    t.string "status", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["page_id", "number"], name: "index_keystone_ui_pages_versions_on_page_id_and_number", unique: true
    t.index ["page_id"], name: "index_keystone_ui_pages_versions_on_one_live_per_page", unique: true, where: "status = 'live'"
    t.index ["page_id"], name: "index_keystone_ui_pages_versions_on_page_id"
  end

  create_table "teams", force: :cascade do |t|
    t.string "name", null: false
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "keystone_ui_pages_pdfs", "keystone_ui_pages_versions", column: "version_id"
  add_foreign_key "keystone_ui_pages_versions", "keystone_ui_pages_pages", column: "page_id"
end
