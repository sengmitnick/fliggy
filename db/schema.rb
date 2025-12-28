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

ActiveRecord::Schema[7.2].define(version: 2025_12_27_145149) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

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

  create_table "admin_oplogs", force: :cascade do |t|
    t.bigint "administrator_id", null: false
    t.string "action"
    t.string "resource_type"
    t.integer "resource_id"
    t.string "ip_address"
    t.text "user_agent"
    t.text "details"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action"], name: "index_admin_oplogs_on_action"
    t.index ["administrator_id"], name: "index_admin_oplogs_on_administrator_id"
    t.index ["created_at"], name: "index_admin_oplogs_on_created_at"
    t.index ["resource_type", "resource_id"], name: "index_admin_oplogs_on_resource_type_and_resource_id"
  end

  create_table "administrators", force: :cascade do |t|
    t.string "name", null: false
    t.string "password_digest"
    t.string "role", null: false
    t.boolean "first_login", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_administrators_on_name", unique: true
    t.index ["role"], name: "index_administrators_on_role"
  end

  create_table "bookings", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "flight_id"
    t.string "passenger_name"
    t.string "passenger_id_number"
    t.string "contact_phone"
    t.decimal "total_price"
    t.string "status", default: "pending"
    t.boolean "accept_terms", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "insurance_type"
    t.decimal "insurance_price"
    t.index ["flight_id"], name: "index_bookings_on_flight_id"
    t.index ["user_id"], name: "index_bookings_on_user_id"
  end

  create_table "brand_memberships", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "brand_name"
    t.string "member_number"
    t.string "member_level"
    t.string "status", default: "pending"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_brand_memberships_on_user_id"
  end

  create_table "cities", force: :cascade do |t|
    t.string "name"
    t.string "pinyin"
    t.string "airport_code"
    t.string "region"
    t.boolean "is_hot", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "themes"
    t.index ["is_hot"], name: "index_cities_on_is_hot"
    t.index ["name"], name: "index_cities_on_name", unique: true
    t.index ["pinyin"], name: "index_cities_on_pinyin"
  end

  create_table "destinations", force: :cascade do |t|
    t.string "name"
    t.string "region"
    t.text "description"
    t.string "image_url"
    t.boolean "is_hot", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug"
    t.index ["slug"], name: "index_destinations_on_slug", unique: true
  end

  create_table "flight_offers", force: :cascade do |t|
    t.bigint "flight_id"
    t.string "provider_name"
    t.string "offer_type", default: "standard"
    t.decimal "price"
    t.decimal "original_price"
    t.decimal "cashback_amount", default: "0.0"
    t.text "discount_items"
    t.string "seat_class", default: "economy"
    t.text "services"
    t.text "tags"
    t.string "baggage_info"
    t.boolean "meal_included", default: false
    t.string "refund_policy"
    t.boolean "is_featured", default: false
    t.integer "display_order", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["flight_id"], name: "index_flight_offers_on_flight_id"
  end

  create_table "flights", force: :cascade do |t|
    t.string "departure_city"
    t.string "destination_city"
    t.datetime "departure_time"
    t.datetime "arrival_time"
    t.string "departure_airport"
    t.string "arrival_airport"
    t.string "airline"
    t.string "flight_number"
    t.string "aircraft_type"
    t.decimal "price"
    t.decimal "discount_price", default: "0.0"
    t.string "seat_class", default: "economy"
    t.integer "available_seats", default: 100
    t.date "flight_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at"
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_type", "sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_type_and_sluggable_id"
  end

  create_table "good_job_batches", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.jsonb "serialized_properties"
    t.text "on_finish"
    t.text "on_success"
    t.text "on_discard"
    t.text "callback_queue_name"
    t.integer "callback_priority"
    t.datetime "enqueued_at"
    t.datetime "discarded_at"
    t.datetime "finished_at"
    t.datetime "jobs_finished_at"
  end

  create_table "good_job_executions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "active_job_id", null: false
    t.text "job_class"
    t.text "queue_name"
    t.jsonb "serialized_params"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.text "error"
    t.integer "error_event", limit: 2
    t.text "error_backtrace", array: true
    t.uuid "process_id"
    t.interval "duration"
    t.index ["active_job_id", "created_at"], name: "index_good_job_executions_on_active_job_id_and_created_at"
    t.index ["process_id", "created_at"], name: "index_good_job_executions_on_process_id_and_created_at"
  end

  create_table "good_job_processes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "state"
    t.integer "lock_type", limit: 2
  end

  create_table "good_job_settings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "key"
    t.jsonb "value"
    t.index ["key"], name: "index_good_job_settings_on_key", unique: true
  end

  create_table "good_jobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "queue_name"
    t.integer "priority"
    t.jsonb "serialized_params"
    t.datetime "scheduled_at"
    t.datetime "performed_at"
    t.datetime "finished_at"
    t.text "error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "active_job_id"
    t.text "concurrency_key"
    t.text "cron_key"
    t.uuid "retried_good_job_id"
    t.datetime "cron_at"
    t.uuid "batch_id"
    t.uuid "batch_callback_id"
    t.boolean "is_discrete"
    t.integer "executions_count"
    t.text "job_class"
    t.integer "error_event", limit: 2
    t.text "labels", array: true
    t.uuid "locked_by_id"
    t.datetime "locked_at"
    t.index ["active_job_id", "created_at"], name: "index_good_jobs_on_active_job_id_and_created_at"
    t.index ["batch_callback_id"], name: "index_good_jobs_on_batch_callback_id", where: "(batch_callback_id IS NOT NULL)"
    t.index ["batch_id"], name: "index_good_jobs_on_batch_id", where: "(batch_id IS NOT NULL)"
    t.index ["concurrency_key", "created_at"], name: "index_good_jobs_on_concurrency_key_and_created_at"
    t.index ["concurrency_key"], name: "index_good_jobs_on_concurrency_key_when_unfinished", where: "(finished_at IS NULL)"
    t.index ["cron_key", "created_at"], name: "index_good_jobs_on_cron_key_and_created_at_cond", where: "(cron_key IS NOT NULL)"
    t.index ["cron_key", "cron_at"], name: "index_good_jobs_on_cron_key_and_cron_at_cond", unique: true, where: "(cron_key IS NOT NULL)"
    t.index ["finished_at"], name: "index_good_jobs_jobs_on_finished_at", where: "((retried_good_job_id IS NULL) AND (finished_at IS NOT NULL))"
    t.index ["labels"], name: "index_good_jobs_on_labels", where: "(labels IS NOT NULL)", using: :gin
    t.index ["locked_by_id"], name: "index_good_jobs_on_locked_by_id", where: "(locked_by_id IS NOT NULL)"
    t.index ["priority", "created_at"], name: "index_good_job_jobs_for_candidate_lookup", where: "(finished_at IS NULL)"
    t.index ["priority", "created_at"], name: "index_good_jobs_jobs_on_priority_created_at_when_unfinished", order: { priority: "DESC NULLS LAST" }, where: "(finished_at IS NULL)"
    t.index ["priority", "scheduled_at"], name: "index_good_jobs_on_priority_scheduled_at_unfinished_unlocked", where: "((finished_at IS NULL) AND (locked_by_id IS NULL))"
    t.index ["queue_name", "scheduled_at"], name: "index_good_jobs_on_queue_name_and_scheduled_at", where: "(finished_at IS NULL)"
    t.index ["scheduled_at"], name: "index_good_jobs_on_scheduled_at", where: "(finished_at IS NULL)"
  end

  create_table "itineraries", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title"
    t.date "start_date"
    t.date "end_date"
    t.string "destination"
    t.string "status", default: "upcoming"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "start_date"], name: "index_itineraries_on_user_id_and_start_date"
    t.index ["user_id", "status"], name: "index_itineraries_on_user_id_and_status"
    t.index ["user_id"], name: "index_itineraries_on_user_id"
  end

  create_table "itinerary_items", force: :cascade do |t|
    t.bigint "itinerary_id", null: false
    t.string "item_type"
    t.string "bookable_type"
    t.integer "bookable_id"
    t.date "item_date"
    t.integer "sequence", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bookable_type", "bookable_id"], name: "index_itinerary_items_on_bookable_type_and_bookable_id"
    t.index ["itinerary_id", "sequence"], name: "index_itinerary_items_on_itinerary_id_and_sequence"
    t.index ["itinerary_id"], name: "index_itinerary_items_on_itinerary_id"
  end

  create_table "membership_benefits", force: :cascade do |t|
    t.string "name"
    t.string "level_required", default: "F1"
    t.string "icon"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "memberships", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "level", default: "F1"
    t.integer "points", default: 0
    t.integer "experience", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "notification_settings", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "category"
    t.boolean "enabled", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "category"], name: "index_notification_settings_on_user_id_and_category", unique: true
    t.index ["user_id"], name: "index_notification_settings_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "category"
    t.string "title"
    t.text "content"
    t.boolean "read", default: false
    t.integer "badge_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "category"], name: "index_notifications_on_user_id_and_category"
    t.index ["user_id", "read"], name: "index_notifications_on_user_id_and_read"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "passengers", force: :cascade do |t|
    t.string "name"
    t.string "id_type", default: "身份证"
    t.string "id_number"
    t.string "phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_passengers_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "tour_products", force: :cascade do |t|
    t.bigint "destination_id"
    t.string "name"
    t.string "product_type", default: "attraction"
    t.string "category", default: "local"
    t.decimal "price", default: "0.0"
    t.decimal "original_price", default: "0.0"
    t.integer "sales_count", default: 0
    t.decimal "rating", default: "5.0"
    t.text "tags"
    t.text "description"
    t.string "image_url"
    t.integer "rank", default: 0
    t.boolean "is_featured", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["destination_id"], name: "index_tour_products_on_destination_id"
  end

  create_table "trains", force: :cascade do |t|
    t.string "departure_city"
    t.string "arrival_city"
    t.datetime "departure_time"
    t.datetime "arrival_time"
    t.integer "duration"
    t.string "train_number"
    t.text "seat_types"
    t.decimal "price_second_class"
    t.decimal "price_first_class"
    t.decimal "price_business_class"
    t.integer "available_seats"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email", null: false
    t.string "password_digest"
    t.boolean "verified", default: false, null: false
    t.string "provider"
    t.string "uid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "airline_member", default: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "admin_oplogs", "administrators"
  add_foreign_key "brand_memberships", "users"
  add_foreign_key "itineraries", "users"
  add_foreign_key "itinerary_items", "itineraries"
  add_foreign_key "memberships", "users"
  add_foreign_key "notification_settings", "users"
  add_foreign_key "notifications", "users"
  add_foreign_key "passengers", "users"
  add_foreign_key "sessions", "users"
end
