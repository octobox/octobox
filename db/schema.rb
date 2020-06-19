# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_06_19_095214) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_stat_statements"
  enable_extension "plpgsql"

  create_table "app_installation_permissions", force: :cascade do |t|
    t.integer "app_installation_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "app_installations", force: :cascade do |t|
    t.integer "github_id"
    t.integer "app_id"
    t.string "account_login"
    t.integer "account_id"
    t.string "account_type"
    t.string "target_type"
    t.integer "target_id"
    t.string "permission_pull_requests"
    t.string "permission_issues"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "permission_statuses"
  end

  create_table "comments", force: :cascade do |t|
    t.integer "subject_id"
    t.bigint "github_id"
    t.string "author"
    t.string "author_association"
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "review_state"
    t.string "url"
    t.index ["subject_id"], name: "index_comments_on_subject_id"
  end

  create_table "labels", force: :cascade do |t|
    t.string "name"
    t.string "color"
    t.bigint "subject_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "github_id"
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
    t.string "last_read_at"
    t.string "url"
    t.boolean "archived", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "starred", default: false
    t.string "repository_owner_name", default: ""
    t.string "latest_comment_url"
    t.datetime "muted_at"
    t.index ["muted_at"], name: "index_notifications_on_muted_at"
    t.index ["repository_full_name"], name: "index_notifications_on_repository_full_name"
    t.index ["subject_url"], name: "index_notifications_on_subject_url"
    t.index ["user_id", "archived", "updated_at"], name: "index_notifications_on_user_id_and_archived_and_updated_at"
    t.index ["user_id", "github_id"], name: "index_notifications_on_user_id_and_github_id", unique: true
  end

  create_table "pinned_searches", force: :cascade do |t|
    t.bigint "user_id"
    t.string "query"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_pinned_searches_on_user_id"
  end

  create_table "repositories", force: :cascade do |t|
    t.string "full_name", null: false
    t.integer "github_id"
    t.boolean "private"
    t.string "owner"
    t.datetime "last_synced_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "app_installation_id"
    t.index ["full_name"], name: "index_repositories_on_full_name", unique: true
    t.index ["github_id"], name: "index_repositories_on_github_id"
  end

  create_table "subjects", force: :cascade do |t|
    t.string "url"
    t.string "state"
    t.string "author"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "html_url"
    t.string "assignees", default: "::"
    t.integer "github_id"
    t.string "repository_full_name"
    t.boolean "locked"
    t.string "sha"
    t.string "status"
    t.text "body"
    t.integer "comment_count"
    t.boolean "draft", default: false
    t.index ["repository_full_name"], name: "index_subjects_on_repository_full_name"
    t.index ["url"], name: "index_subjects_on_url"
  end

  create_table "subscription_plans", force: :cascade do |t|
    t.integer "github_id"
    t.string "name"
    t.string "description"
    t.integer "monthly_price_in_cents"
    t.integer "yearly_price_in_cents"
    t.string "price_model"
    t.boolean "has_free_trial"
    t.string "unit_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "number"
  end

  create_table "subscription_purchases", force: :cascade do |t|
    t.integer "subscription_plan_id"
    t.integer "account_id"
    t.string "billing_cycle"
    t.integer "unit_count"
    t.boolean "on_free_trial"
    t.datetime "free_trial_ends_on"
    t.datetime "next_billing_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "oc_transactionid"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.integer "github_id", null: false
    t.string "github_login", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_synced_at"
    t.integer "refresh_interval", default: 0
    t.string "api_token"
    t.string "sync_job_id"
    t.string "encrypted_access_token"
    t.string "encrypted_access_token_iv"
    t.string "encrypted_personal_access_token"
    t.string "encrypted_personal_access_token_iv"
    t.string "encrypted_app_token"
    t.string "encrypted_app_token_iv"
    t.string "theme", default: "light"
    t.boolean "display_comments", default: true
    t.index ["api_token"], name: "index_users_on_api_token", unique: true
    t.index ["github_id"], name: "index_users_on_github_id", unique: true
  end

  add_foreign_key "labels", "subjects", on_update: :cascade, on_delete: :cascade
end
