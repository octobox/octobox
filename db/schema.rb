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

ActiveRecord::Schema.define(version: 2018_08_10_075442) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "app_installations", force: :cascade do |t|
    t.integer "github_id"
    t.string "account_login"
    t.integer "account_id"
    t.jsonb "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "comments", force: :cascade do |t|
    t.integer "subject_id"
    t.integer "github_id"
    t.string "author"
    t.string "author_association"
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "labels", force: :cascade do |t|
    t.string "name"
    t.string "color"
    t.bigint "subject_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "github_id"
    t.index ["name"], name: "index_labels_on_name"
    t.index ["subject_id"], name: "index_labels_on_subject_id"
  end

  create_table "notifications", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "github_id"
    t.integer "repository_id"
    t.string "repository_full_name"
    t.text "subject_title"
    t.string "subject_url"
    t.string "subject_type"
    t.string "reason"
    t.boolean "unread"
    t.datetime "updated_at", null: false
    t.string "last_read_at"
    t.string "url"
    t.boolean "archived", default: false
    t.datetime "created_at", null: false
    t.boolean "starred", default: false
    t.string "repository_owner_name", default: ""
    t.string "latest_comment_url"
    t.index ["subject_url"], name: "index_notifications_on_subject_url"
    t.index ["user_id", "archived", "updated_at"], name: "index_notifications_on_user_id_and_archived_and_updated_at"
    t.index ["user_id", "github_id"], name: "index_notifications_on_user_id_and_github_id", unique: true
  end

  create_table "repositories", force: :cascade do |t|
    t.integer "github_id"
    t.integer "app_installation_id"
    t.string "full_name"
    t.string "owner"
    t.boolean "private"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "subjects", force: :cascade do |t|
    t.string "url"
    t.string "state"
    t.string "author"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "html_url"
    t.text "body"
    t.string "assignees", default: [], array: true
    t.index ["url"], name: "index_subjects_on_url"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.integer "github_id", null: false
    t.string "github_login", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_synced_at"
    t.integer "refresh_interval", default: 0
    t.string "api_token"
    t.string "app_token"
    t.string "encrypted_access_token"
    t.string "encrypted_access_token_iv"
    t.string "encrypted_personal_access_token"
    t.string "encrypted_personal_access_token_iv"
    t.string "theme", default: "light"
    t.index ["api_token"], name: "index_users_on_api_token", unique: true
    t.index ["github_id"], name: "index_users_on_github_id", unique: true
  end

  add_foreign_key "labels", "subjects", on_update: :cascade, on_delete: :cascade
end
