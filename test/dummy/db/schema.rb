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

ActiveRecord::Schema[8.1].define(version: 2026_10_14_120001) do
  create_table "keystone_ui_pages_pages", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.json "document", null: false
    t.string "owner_type"
    t.integer "owner_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_type", "owner_id", "slug"], name: "index_keystone_ui_pages_pages_on_owner_and_slug", unique: true
    t.index ["owner_type", "owner_id"], name: "index_keystone_ui_pages_pages_on_owner"
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

  add_foreign_key "keystone_ui_pages_versions", "keystone_ui_pages_pages", column: "page_id"
end
