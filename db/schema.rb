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

ActiveRecord::Schema[7.2].define(version: 2026_01_18_105101) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "abroad_brands", force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.string "country"
    t.string "logo_url"
    t.text "description"
    t.string "category", default: "duty_free"
    t.boolean "featured", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "abroad_coupons", force: :cascade do |t|
    t.string "title"
    t.integer "abroad_brand_id"
    t.integer "abroad_shop_id"
    t.string "discount_type"
    t.string "discount_value"
    t.text "description"
    t.date "valid_from"
    t.date "valid_until"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "abroad_shops", force: :cascade do |t|
    t.string "name"
    t.integer "abroad_brand_id"
    t.string "city"
    t.text "address"
    t.decimal "latitude"
    t.decimal "longitude"
    t.string "image_url"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "abroad_ticket_orders", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "abroad_ticket_id"
    t.string "passenger_name"
    t.string "passenger_id_number"
    t.string "contact_phone"
    t.string "contact_email"
    t.string "passenger_type", default: "1adult"
    t.string "seat_category", default: "自由席"
    t.decimal "total_price", default: "0.0"
    t.string "status", default: "pending"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "order_number"
    t.index ["abroad_ticket_id"], name: "index_abroad_ticket_orders_on_abroad_ticket_id"
    t.index ["user_id"], name: "index_abroad_ticket_orders_on_user_id"
  end

  create_table "abroad_tickets", force: :cascade do |t|
    t.string "region", default: "japan"
    t.string "ticket_type", default: "train"
    t.string "origin"
    t.string "destination"
    t.date "departure_date"
    t.string "time_slot_start"
    t.string "time_slot_end"
    t.decimal "price", default: "0.0"
    t.string "seat_type"
    t.string "status", default: "available"
    t.string "origin_en"
    t.string "destination_en"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

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

  create_table "addresses", force: :cascade do |t|
    t.bigint "user_id"
    t.string "name"
    t.string "phone"
    t.string "province"
    t.string "city"
    t.string "district"
    t.string "detail"
    t.boolean "is_default", default: false
    t.string "address_type", default: "delivery"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_addresses_on_user_id"
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

  create_table "booking_options", force: :cascade do |t|
    t.bigint "train_id"
    t.string "title"
    t.text "description"
    t.decimal "extra_fee", default: "0.0"
    t.text "benefits"
    t.integer "priority", default: 0
    t.boolean "is_active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["train_id"], name: "index_booking_options_on_train_id"
  end

  create_table "booking_travelers", force: :cascade do |t|
    t.integer "tour_group_booking_id"
    t.string "traveler_name"
    t.string "id_number"
    t.string "traveler_type", default: "adult"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "deep_travel_booking_id"
    t.index ["deep_travel_booking_id"], name: "index_booking_travelers_on_deep_travel_booking_id"
    t.index ["tour_group_booking_id"], name: "index_booking_travelers_on_tour_group_booking_id"
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
    t.string "trip_type", default: "one_way"
    t.integer "return_flight_id"
    t.date "return_date"
    t.integer "return_offer_id"
    t.jsonb "multi_city_flights"
    t.index ["flight_id"], name: "index_bookings_on_flight_id"
    t.index ["return_flight_id"], name: "index_bookings_on_return_flight_id"
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

  create_table "bus_routes", force: :cascade do |t|
    t.string "origin"
    t.string "destination"
    t.integer "duration"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "bus_ticket_orders", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "bus_ticket_id"
    t.string "passenger_name"
    t.string "passenger_id_number"
    t.string "contact_phone"
    t.string "departure_station"
    t.string "arrival_station"
    t.string "insurance_type"
    t.decimal "insurance_price"
    t.decimal "total_price"
    t.string "status", default: "pending"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bus_ticket_id"], name: "index_bus_ticket_orders_on_bus_ticket_id"
    t.index ["user_id"], name: "index_bus_ticket_orders_on_user_id"
  end

  create_table "bus_tickets", force: :cascade do |t|
    t.string "origin"
    t.string "destination"
    t.date "departure_date"
    t.string "departure_time"
    t.string "arrival_time"
    t.decimal "price", default: "0.0"
    t.string "status", default: "available"
    t.string "seat_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "departure_station"
    t.string "arrival_station"
    t.string "route_description"
  end

  create_table "car_orders", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "car_id"
    t.string "driver_name"
    t.string "driver_id_number"
    t.string "contact_phone"
    t.datetime "pickup_datetime"
    t.datetime "return_datetime"
    t.string "pickup_location"
    t.string "status", default: "pending"
    t.decimal "total_price", default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["car_id"], name: "index_car_orders_on_car_id"
    t.index ["user_id"], name: "index_car_orders_on_user_id"
  end

  create_table "cars", force: :cascade do |t|
    t.string "brand"
    t.string "car_model"
    t.string "category", default: "经济轿车"
    t.integer "seats", default: 5
    t.integer "doors", default: 4
    t.string "transmission", default: "自动挡"
    t.string "fuel_type"
    t.string "engine"
    t.decimal "price_per_day", default: "0.0"
    t.decimal "total_price", default: "0.0"
    t.decimal "discount_amount", default: "0.0"
    t.string "location", default: "武汉"
    t.string "pickup_location"
    t.text "features"
    t.text "tags"
    t.boolean "is_featured", default: false
    t.boolean "is_available", default: true
    t.integer "sales_rank", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "image_url"
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

  create_table "countries", force: :cascade do |t|
    t.string "name"
    t.string "code"
    t.string "slug"
    t.string "region"
    t.boolean "visa_free", default: false
    t.string "image_url"
    t.text "description"
    t.text "visa_requirements"
    t.jsonb "statistics", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "deep_travel_bookings", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "deep_travel_guide_id"
    t.bigint "deep_travel_product_id"
    t.date "travel_date"
    t.integer "adult_count", default: 1
    t.integer "child_count", default: 0
    t.string "traveler_name"
    t.string "traveler_id_number"
    t.string "traveler_phone"
    t.string "contact_name"
    t.string "contact_phone"
    t.decimal "total_price", precision: 10, scale: 2
    t.decimal "insurance_price", precision: 10, scale: 2
    t.string "status", default: "pending"
    t.string "order_number"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deep_travel_guide_id"], name: "index_deep_travel_bookings_on_deep_travel_guide_id"
    t.index ["deep_travel_product_id"], name: "index_deep_travel_bookings_on_deep_travel_product_id"
    t.index ["user_id"], name: "index_deep_travel_bookings_on_user_id"
  end

  create_table "deep_travel_guides", force: :cascade do |t|
    t.string "name"
    t.string "title"
    t.text "description"
    t.integer "follower_count", default: 0
    t.integer "experience_years", default: 0
    t.text "specialties"
    t.decimal "price", precision: 10, scale: 2
    t.integer "served_count", default: 0
    t.integer "rank"
    t.decimal "rating", precision: 3, scale: 2
    t.boolean "featured", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "deep_travel_products", force: :cascade do |t|
    t.string "title"
    t.string "subtitle"
    t.string "location"
    t.bigint "deep_travel_guide_id"
    t.decimal "price", precision: 10, scale: 2
    t.integer "sales_count", default: 0
    t.text "description"
    t.text "itinerary"
    t.boolean "featured", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deep_travel_guide_id"], name: "index_deep_travel_products_on_deep_travel_guide_id"
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

  create_table "family_benefits", force: :cascade do |t|
    t.string "verification_status", default: "unverified"
    t.integer "family_members", default: 0
    t.integer "adult_count", default: 0
    t.integer "child_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "family_coupons", force: :cascade do |t|
    t.string "title"
    t.string "coupon_type"
    t.decimal "amount"
    t.date "valid_until"
    t.string "status", default: "available"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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

  create_table "flight_packages", force: :cascade do |t|
    t.string "title"
    t.string "subtitle"
    t.decimal "price", default: "0.0"
    t.decimal "original_price", default: "0.0"
    t.string "discount_label"
    t.string "badge_text"
    t.string "badge_color", default: "#FF5722"
    t.string "destination"
    t.string "image_url"
    t.integer "valid_days", default: 365
    t.text "description"
    t.text "features"
    t.string "status", default: "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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

  create_table "hotel_bookings", force: :cascade do |t|
    t.bigint "hotel_id"
    t.bigint "user_id"
    t.bigint "hotel_room_id"
    t.date "check_in_date"
    t.date "check_out_date"
    t.integer "rooms_count", default: 1
    t.integer "adults_count", default: 1
    t.integer "children_count", default: 0
    t.string "guest_name"
    t.string "guest_phone"
    t.decimal "total_price"
    t.decimal "original_price"
    t.decimal "discount_amount", default: "0.0"
    t.string "payment_method", default: "在线付"
    t.string "coupon_code"
    t.text "special_requests"
    t.string "status", default: "pending"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "insurance_type"
    t.decimal "insurance_price"
    t.datetime "locked_until"
    t.index ["hotel_id"], name: "index_hotel_bookings_on_hotel_id"
    t.index ["hotel_room_id"], name: "index_hotel_bookings_on_hotel_room_id"
    t.index ["user_id"], name: "index_hotel_bookings_on_user_id"
  end

  create_table "hotel_facilities", force: :cascade do |t|
    t.bigint "hotel_id"
    t.string "name"
    t.string "icon"
    t.string "description"
    t.string "category"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["hotel_id"], name: "index_hotel_facilities_on_hotel_id"
  end

  create_table "hotel_package_orders", force: :cascade do |t|
    t.bigint "hotel_package_id"
    t.bigint "user_id"
    t.string "order_number"
    t.integer "quantity", default: 1
    t.decimal "total_price"
    t.string "status", default: "pending"
    t.string "payment_method"
    t.datetime "purchased_at"
    t.integer "used_count", default: 0
    t.datetime "valid_until"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "package_option_id", null: false
    t.bigint "passenger_id", null: false
    t.string "booking_type", default: "stockup"
    t.string "contact_name"
    t.string "contact_phone"
    t.index ["hotel_package_id"], name: "index_hotel_package_orders_on_hotel_package_id"
    t.index ["order_number"], name: "index_hotel_package_orders_on_order_number"
    t.index ["package_option_id"], name: "index_hotel_package_orders_on_package_option_id"
    t.index ["passenger_id"], name: "index_hotel_package_orders_on_passenger_id"
    t.index ["user_id"], name: "index_hotel_package_orders_on_user_id"
  end

  create_table "hotel_packages", force: :cascade do |t|
    t.string "brand_name"
    t.string "title"
    t.text "description"
    t.decimal "price"
    t.decimal "original_price"
    t.integer "sales_count", default: 0
    t.boolean "is_featured", default: false
    t.integer "valid_days", default: 365
    t.text "terms"
    t.string "brand_logo_url"
    t.string "region"
    t.string "package_type", default: "standard"
    t.integer "display_order", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "hotel_id"
    t.string "brand"
    t.string "city"
    t.integer "night_count", default: 2
    t.boolean "refundable", default: false
    t.boolean "instant_booking", default: false
    t.boolean "luxury", default: false
    t.string "slug"
    t.index ["brand_name"], name: "index_hotel_packages_on_brand_name"
    t.index ["hotel_id"], name: "index_hotel_packages_on_hotel_id"
    t.index ["slug"], name: "index_hotel_packages_on_slug", unique: true
  end

  create_table "hotel_policies", force: :cascade do |t|
    t.bigint "hotel_id"
    t.string "check_in_time"
    t.string "check_out_time"
    t.string "pet_policy"
    t.string "breakfast_type"
    t.string "breakfast_hours"
    t.decimal "breakfast_price", default: "0.0"
    t.text "payment_methods"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["hotel_id"], name: "index_hotel_policies_on_hotel_id"
  end

  create_table "hotel_reviews", force: :cascade do |t|
    t.bigint "hotel_id"
    t.bigint "user_id"
    t.decimal "rating", default: "5.0"
    t.text "comment"
    t.integer "helpful_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["hotel_id"], name: "index_hotel_reviews_on_hotel_id"
    t.index ["user_id"], name: "index_hotel_reviews_on_user_id"
  end

  create_table "hotel_rooms", force: :cascade do |t|
    t.integer "hotel_id"
    t.string "room_type", default: "标准间"
    t.string "bed_type"
    t.decimal "price"
    t.decimal "original_price"
    t.string "area"
    t.integer "max_guests", default: 2
    t.boolean "has_window", default: true
    t.integer "available_rooms", default: 10
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "room_category", default: "overnight"
    t.index ["room_category"], name: "index_hotel_rooms_on_room_category"
  end

  create_table "hotels", force: :cascade do |t|
    t.string "name"
    t.string "city", default: "深圳市"
    t.text "address"
    t.decimal "rating", default: "4.5"
    t.decimal "price"
    t.decimal "original_price"
    t.string "distance"
    t.text "features"
    t.integer "star_level", default: 4
    t.string "image_url"
    t.boolean "is_featured", default: false
    t.integer "display_order", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "hotel_type", default: "hotel"
    t.string "region"
    t.boolean "is_domestic", default: true
    t.string "brand"
    t.index ["hotel_type"], name: "index_hotels_on_hotel_type"
    t.index ["is_domestic"], name: "index_hotels_on_is_domestic"
    t.index ["region"], name: "index_hotels_on_region"
  end

  create_table "internet_data_plans", force: :cascade do |t|
    t.string "name"
    t.string "region"
    t.integer "validity_days"
    t.string "data_limit"
    t.decimal "price"
    t.string "phone_number"
    t.string "carrier"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "internet_orders", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "orderable_id"
    t.string "order_type"
    t.string "region"
    t.integer "quantity", default: 1
    t.decimal "total_price"
    t.string "status", default: "pending"
    t.string "delivery_method"
    t.jsonb "delivery_info"
    t.jsonb "contact_info"
    t.jsonb "rental_info"
    t.string "order_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "orderable_type"
    t.index ["orderable_id"], name: "index_internet_orders_on_orderable_id"
    t.index ["orderable_type", "orderable_id"], name: "index_internet_orders_on_orderable_type_and_orderable_id"
    t.index ["user_id"], name: "index_internet_orders_on_user_id"
  end

  create_table "internet_sim_cards", force: :cascade do |t|
    t.string "name"
    t.string "region"
    t.integer "validity_days"
    t.string "data_limit"
    t.decimal "price"
    t.text "features"
    t.integer "sales_count", default: 0
    t.string "shop_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "internet_wifis", force: :cascade do |t|
    t.string "name"
    t.string "region"
    t.string "network_type"
    t.string "data_limit"
    t.decimal "daily_price"
    t.text "features"
    t.integer "sales_count", default: 0
    t.string "shop_name"
    t.decimal "deposit", default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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

  create_table "package_options", force: :cascade do |t|
    t.bigint "hotel_package_id"
    t.string "name"
    t.decimal "price"
    t.decimal "original_price"
    t.integer "night_count"
    t.text "description"
    t.boolean "can_split", default: true
    t.integer "display_order", default: 0
    t.boolean "is_active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["hotel_package_id"], name: "index_package_options_on_hotel_package_id"
  end

  create_table "passengers", force: :cascade do |t|
    t.string "name"
    t.string "id_type", default: "身份证"
    t.string "id_number"
    t.string "phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.boolean "is_self", default: false, null: false
    t.index ["user_id", "is_self"], name: "index_passengers_on_user_id_and_is_self"
    t.index ["user_id"], name: "index_passengers_on_user_id"
  end

  create_table "price_alerts", force: :cascade do |t|
    t.string "departure"
    t.string "destination"
    t.decimal "expected_price"
    t.date "departure_date"
    t.string "status", default: "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "rooms", force: :cascade do |t|
    t.bigint "hotel_id"
    t.string "name"
    t.string "size"
    t.string "bed_type"
    t.decimal "price", default: "0.0"
    t.decimal "original_price", default: "0.0"
    t.text "amenities"
    t.boolean "breakfast_included", default: false
    t.string "cancellation_policy"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["hotel_id"], name: "index_rooms_on_hotel_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "tour_group_bookings", force: :cascade do |t|
    t.integer "tour_group_product_id"
    t.integer "tour_package_id"
    t.integer "user_id"
    t.date "travel_date"
    t.integer "adult_count", default: 1
    t.integer "child_count", default: 0
    t.string "contact_name"
    t.string "contact_phone"
    t.string "insurance_type", default: "none"
    t.string "status", default: "pending"
    t.decimal "total_price"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tour_group_product_id"], name: "index_tour_group_bookings_on_tour_group_product_id"
    t.index ["tour_package_id"], name: "index_tour_group_bookings_on_tour_package_id"
    t.index ["user_id"], name: "index_tour_group_bookings_on_user_id"
  end

  create_table "tour_group_products", force: :cascade do |t|
    t.string "title"
    t.string "subtitle"
    t.string "tour_category", default: "group_tour"
    t.string "destination"
    t.integer "duration", default: 1
    t.string "departure_city"
    t.decimal "price", default: "0.0"
    t.decimal "original_price", default: "0.0"
    t.decimal "rating", default: "0.0"
    t.string "rating_desc"
    t.text "highlights"
    t.text "tags"
    t.string "provider"
    t.integer "sales_count", default: 0
    t.string "badge"
    t.string "departure_label"
    t.string "image_url"
    t.boolean "is_featured", default: false
    t.integer "display_order", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "travel_agency_id", null: false
    t.integer "reward_points", default: 0
    t.boolean "requires_merchant_confirm", default: false
    t.integer "merchant_confirm_hours", default: 48
    t.boolean "success_rate_high", default: false
    t.text "description"
    t.text "cost_includes"
    t.text "cost_excludes"
    t.text "safety_notice"
    t.text "booking_notice"
    t.text "insurance_notice"
    t.text "cancellation_policy"
    t.text "price_explanation"
    t.text "group_tour_notice"
    t.boolean "custom_tour_available", default: false
    t.index ["travel_agency_id"], name: "index_tour_group_products_on_travel_agency_id"
  end

  create_table "tour_itinerary_days", force: :cascade do |t|
    t.bigint "tour_group_product_id"
    t.integer "day_number", default: 1
    t.string "title"
    t.text "attractions"
    t.text "assembly_point"
    t.text "assembly_details"
    t.text "disassembly_point"
    t.text "disassembly_details"
    t.string "transportation"
    t.text "service_info"
    t.integer "duration_minutes", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tour_group_product_id"], name: "index_tour_itinerary_days_on_tour_group_product_id"
  end

  create_table "tour_packages", force: :cascade do |t|
    t.bigint "tour_group_product_id"
    t.string "name"
    t.decimal "price", default: "0.0"
    t.decimal "child_price", default: "0.0"
    t.integer "purchase_count", default: 0
    t.text "description"
    t.boolean "is_featured", default: false
    t.integer "display_order", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tour_group_product_id"], name: "index_tour_packages_on_tour_group_product_id"
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
    t.string "tour_type"
    t.integer "duration"
    t.string "departure_city"
    t.string "rating_desc"
    t.text "highlights"
    t.string "provider"
    t.string "badge"
    t.string "departure_label"
    t.string "price_suffix", default: "起"
    t.index ["destination_id"], name: "index_tour_products_on_destination_id"
  end

  create_table "tour_reviews", force: :cascade do |t|
    t.bigint "tour_group_product_id"
    t.bigint "user_id"
    t.decimal "rating", default: "5.0"
    t.decimal "guide_attitude", default: "5.0"
    t.decimal "meal_quality", default: "5.0"
    t.decimal "itinerary_arrangement", default: "5.0"
    t.decimal "travel_transportation", default: "5.0"
    t.text "comment"
    t.boolean "is_featured", default: false
    t.integer "helpful_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tour_group_product_id"], name: "index_tour_reviews_on_tour_group_product_id"
    t.index ["user_id"], name: "index_tour_reviews_on_user_id"
  end

  create_table "train_bookings", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "train_id"
    t.string "passenger_name"
    t.string "passenger_id_number"
    t.string "contact_phone"
    t.string "seat_type"
    t.string "carriage_number"
    t.string "seat_number"
    t.decimal "total_price"
    t.string "insurance_type"
    t.decimal "insurance_price"
    t.string "status", default: "pending"
    t.boolean "accept_terms", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["train_id"], name: "index_train_bookings_on_train_id"
    t.index ["user_id"], name: "index_train_bookings_on_user_id"
  end

  create_table "train_seats", force: :cascade do |t|
    t.bigint "train_id"
    t.string "seat_type", default: "second_class"
    t.decimal "price", default: "0.0"
    t.integer "available_count", default: 0
    t.integer "total_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["train_id"], name: "index_train_seats_on_train_id"
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

  create_table "transfer_packages", force: :cascade do |t|
    t.string "name"
    t.string "vehicle_category"
    t.integer "seats"
    t.integer "luggage"
    t.integer "wait_time"
    t.string "refund_policy"
    t.decimal "price", default: "0.0"
    t.decimal "original_price"
    t.decimal "discount_amount", default: "0.0"
    t.text "features"
    t.string "provider"
    t.integer "priority", default: 0
    t.boolean "is_active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "transfers", force: :cascade do |t|
    t.bigint "user_id"
    t.string "transfer_type", default: "airport_pickup"
    t.string "service_type", default: "to_airport"
    t.string "location_from"
    t.string "location_to"
    t.datetime "pickup_datetime"
    t.string "flight_number"
    t.string "train_number"
    t.string "passenger_name"
    t.string "passenger_phone"
    t.string "vehicle_type", default: "economy_5"
    t.string "provider_name"
    t.string "license_plate"
    t.string "driver_name"
    t.string "driver_status", default: "pending"
    t.decimal "total_price", default: "0.0"
    t.decimal "discount_amount", default: "0.0"
    t.string "status", default: "pending"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "transfer_package_id"
    t.index ["transfer_package_id"], name: "index_transfers_on_transfer_package_id"
    t.index ["user_id"], name: "index_transfers_on_user_id"
  end

  create_table "travel_agencies", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "logo_url"
    t.decimal "rating", default: "5.0"
    t.integer "sales_count", default: 0
    t.boolean "is_verified", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_coupons", force: :cascade do |t|
    t.integer "user_id"
    t.integer "abroad_coupon_id"
    t.string "status", default: "unclaimed"
    t.datetime "claimed_at"
    t.datetime "used_at"
    t.datetime "expires_at"
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
    t.jsonb "airline_memberships", default: {}
    t.string "pay_password_digest"
    t.decimal "balance", precision: 10, scale: 2, default: "0.0", null: false
    t.string "phone"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "visa_order_travelers", force: :cascade do |t|
    t.integer "visa_order_id"
    t.string "name"
    t.string "id_number"
    t.string "phone"
    t.string "relationship"
    t.string "passport_number"
    t.date "passport_expiry"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "visa_orders", force: :cascade do |t|
    t.integer "user_id"
    t.integer "visa_product_id"
    t.integer "traveler_count", default: 1
    t.decimal "total_price", default: "0.0"
    t.decimal "unit_price", default: "0.0"
    t.string "status", default: "pending"
    t.date "expected_date"
    t.string "delivery_method", default: "express"
    t.text "delivery_address"
    t.string "contact_name"
    t.string "contact_phone"
    t.text "notes"
    t.boolean "insurance_selected", default: false
    t.decimal "insurance_price", default: "0.0"
    t.string "payment_status", default: "unpaid"
    t.datetime "paid_at"
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "insurance_type"
  end

  create_table "visa_products", force: :cascade do |t|
    t.integer "country_id"
    t.string "name"
    t.string "product_type"
    t.decimal "price", default: "0.0"
    t.decimal "original_price"
    t.string "residence_area"
    t.integer "processing_days"
    t.string "visa_validity"
    t.string "max_stay"
    t.decimal "success_rate", default: "99.9"
    t.jsonb "required_materials", default: []
    t.integer "material_count", default: 0
    t.boolean "can_simplify", default: false
    t.boolean "home_pickup", default: false
    t.boolean "refused_reapply", default: false
    t.boolean "supports_family", default: false
    t.jsonb "features", default: []
    t.text "description"
    t.string "slug"
    t.integer "sales_count", default: 0
    t.string "merchant_name"
    t.string "merchant_avatar"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "admin_oplogs", "administrators"
  add_foreign_key "brand_memberships", "users"
  add_foreign_key "deep_travel_products", "deep_travel_guides"
  add_foreign_key "hotel_package_orders", "package_options"
  add_foreign_key "hotel_package_orders", "passengers"
  add_foreign_key "hotel_packages", "hotels"
  add_foreign_key "itineraries", "users"
  add_foreign_key "itinerary_items", "itineraries"
  add_foreign_key "memberships", "users"
  add_foreign_key "notification_settings", "users"
  add_foreign_key "notifications", "users"
  add_foreign_key "passengers", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "tour_group_products", "travel_agencies"
  add_foreign_key "transfers", "transfer_packages"
end
