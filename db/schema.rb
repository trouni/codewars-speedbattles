# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_07_18_011449) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "battle_invites", force: :cascade do |t|
    t.bigint "battle_id"
    t.bigint "player_id"
    t.boolean "confirmed", default: false
    t.boolean "survived"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["battle_id"], name: "index_battle_invites_on_battle_id"
    t.index ["player_id"], name: "index_battle_invites_on_player_id"
  end

  create_table "battles", force: :cascade do |t|
    t.bigint "room_id"
    t.string "challenge_id"
    t.string "challenge_url"
    t.string "challenge_name"
    t.string "challenge_language"
    t.integer "challenge_rank"
    t.text "challenge_description"
    t.integer "max_survivors"
    t.integer "time_limit"
    t.datetime "end_time"
    t.datetime "start_time"
    t.bigint "winner_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["room_id"], name: "index_battles_on_room_id"
    t.index ["winner_id"], name: "index_battles_on_winner_id"
  end

  create_table "chats", force: :cascade do |t|
    t.string "name"
    t.bigint "room_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["room_id"], name: "index_chats_on_room_id"
  end

  create_table "completed_challenges", force: :cascade do |t|
    t.bigint "user_id"
    t.string "challenge_id"
    t.string "challenge_name"
    t.string "challenge_slug"
    t.datetime "completed_at"
    t.string "completed_languages"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_completed_challenges_on_user_id"
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "chat_id"
    t.string "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_id"], name: "index_messages_on_chat_id"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "room_users", force: :cascade do |t|
    t.bigint "room_id"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["room_id"], name: "index_room_users_on_room_id"
    t.index ["user_id"], name: "index_room_users_on_user_id"
  end

  create_table "rooms", force: :cascade do |t|
    t.string "name"
    t.bigint "moderator_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["moderator_id"], name: "index_rooms_on_moderator_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "username", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.boolean "admin", default: false
    t.integer "codewars_honor"
    t.string "codewars_clan"
    t.integer "codewars_leaderboard_position"
    t.integer "codewars_overall_rank"
    t.integer "codewars_overall_score"
    t.datetime "last_fetched_at"
    t.string "authentication_token", limit: 30
    t.index ["authentication_token"], name: "index_users_on_authentication_token", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "battle_invites", "battles"
  add_foreign_key "battle_invites", "users", column: "player_id"
  add_foreign_key "battles", "rooms"
  add_foreign_key "battles", "users", column: "winner_id"
  add_foreign_key "chats", "rooms"
  add_foreign_key "completed_challenges", "users"
  add_foreign_key "messages", "chats"
  add_foreign_key "messages", "users"
  add_foreign_key "room_users", "rooms"
  add_foreign_key "room_users", "users"
  add_foreign_key "rooms", "users", column: "moderator_id"
end
