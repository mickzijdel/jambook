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

ActiveRecord::Schema[8.1].define(version: 2026_10_30_151355) do
  create_table "songs", force: :cascade do |t|
    t.string "title", null: false
    t.string "artist", null: false
    t.string "title_key", null: false
    t.string "status", default: "maybe", null: false
    t.text "sheet"
    t.string "sheet_format", default: "chordpro", null: false
    t.string "written_key"
    t.integer "written_capo", default: 0, null: false
    t.string "house_key"
    t.boolean "key_guessed", default: false, null: false
    t.text "notes"
    t.string "ug_url"
    t.string "ug_type"
    t.boolean "needs_paste", default: false, null: false
    t.string "listen_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["title_key"], name: "index_songs_on_title_key"
  end

  create_table "taggings", force: :cascade do |t|
    t.integer "song_id", null: false
    t.integer "tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["song_id", "tag_id"], name: "index_taggings_on_song_id_and_tag_id", unique: true
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  add_foreign_key "taggings", "songs"
  add_foreign_key "taggings", "tags"
end
