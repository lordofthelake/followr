# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20180330172325) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "admin_users", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
  end

  add_index "admin_users", ["email"], name: "index_admin_users_on_email", unique: true, using: :btree
  add_index "admin_users", ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true, using: :btree

  create_table "credentials", force: :cascade do |t|
    t.integer  "user_id"
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
    t.string   "twitter_oauth_token"
    t.string   "twitter_oauth_token_secret"
    t.boolean  "is_valid",                   default: true
  end

  create_table "followers", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "source"
    t.integer  "count"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "twitter_follow_preferences", force: :cascade do |t|
    t.integer  "unfollow_after",   default: 1
    t.text     "hashtags",         default: ""
    t.integer  "user_id"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.datetime "rate_limit_until"
    t.boolean  "mass_follow",      default: true
    t.boolean  "mass_unfollow",    default: true
  end

  create_table "twitter_follows", force: :cascade do |t|
    t.integer  "user_id"
    t.boolean  "unfollowed",      default: false
    t.string   "username"
    t.datetime "followed_at"
    t.datetime "unfollowed_at"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.string   "hashtag"
    t.string   "twitter_user_id"
  end

  add_index "twitter_follows", ["user_id"], name: "index_twitter_follows_on_user_id", using: :btree
  add_index "twitter_follows", ["username"], name: "index_twitter_follows_on_username", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.string   "twitter_uid"
    t.string   "name"
    t.string   "twitter_username"
  end

end
