# frozen_string_literal: true

class ChangeAllDataVersionToBigint < ActiveRecord::Migration[7.2]
  # 所有需要修改的表
  TABLES_WITH_DATA_VERSION = %w[
    abroad_brands
    abroad_coupons
    abroad_shops
    abroad_ticket_orders
    abroad_tickets
    addresses
    booking_options
    booking_travelers
    bookings
    brand_memberships
    bus_routes
    bus_ticket_orders
    bus_tickets
    car_orders
    cars
    cities
    contacts
    countries
    deep_travel_bookings
    deep_travel_guides
    deep_travel_products
    destinations
    flight_offers
    flights
    hotel_bookings
    hotel_facilities
    hotel_package_orders
    hotel_packages
    hotel_policies
    hotel_reviews
    hotel_rooms
    hotels
    internet_data_plans
    internet_orders
    internet_sim_cards
    internet_wifis
    itineraries
    itinerary_items
    membership_benefits
    memberships
    notification_settings
    notifications
    package_options
    passengers
    rooms
    tour_group_bookings
    tour_group_products
    tour_itinerary_days
    tour_packages
    tour_products
    tour_reviews
    train_bookings
    train_seats
    trains
    transfer_packages
    transfers
    travel_agencies
    user_coupons
    users
    visa_order_travelers
    visa_orders
    visa_products
  ].freeze

  def up
    puts "\n" + "=" * 80
    puts "正在将所有表的 data_version 从 integer 改为 bigint..."
    puts "=" * 80

    TABLES_WITH_DATA_VERSION.each do |table|
      next unless table_exists?(table.to_sym)
      next unless column_exists?(table.to_sym, :data_version)

      puts "  → 处理表: #{table}"

      policy_name = "#{table}_version_policy"

      # 1. 删除现有的 RLS 策略
      execute "DROP POLICY IF EXISTS #{policy_name} ON #{table}"

      # 2. 修改列类型
      change_column table, :data_version, :bigint, default: 0, null: false

      # 3. 重新创建 RLS 策略（确保与 bigint 类型兼容）
      execute <<-SQL
        CREATE POLICY #{policy_name} ON #{table}
        FOR ALL
        USING (
          data_version = 0 
          OR data_version::text = current_setting('app.data_version', true)
        )
        WITH CHECK (
          data_version::text = current_setting('app.data_version', true)
        )
      SQL
    end

    puts "✓ 完成！共处理 #{TABLES_WITH_DATA_VERSION.count} 个表"
  end

  def down
    puts "\n" + "=" * 80
    puts "正在将所有表的 data_version 从 bigint 改回 integer..."
    puts "=" * 80

    TABLES_WITH_DATA_VERSION.each do |table|
      next unless table_exists?(table.to_sym)
      next unless column_exists?(table.to_sym, :data_version)

      puts "  → 处理表: #{table}"

      policy_name = "#{table}_version_policy"

      # 1. 删除现有的 RLS 策略
      execute "DROP POLICY IF EXISTS #{policy_name} ON #{table}"

      # 2. 修改列类型
      change_column table, :data_version, :integer, default: 0, null: false

      # 3. 重新创建 RLS 策略
      execute <<-SQL
        CREATE POLICY #{policy_name} ON #{table}
        FOR ALL
        USING (
          data_version = 0 
          OR data_version::text = current_setting('app.data_version', true)
        )
        WITH CHECK (
          data_version::text = current_setting('app.data_version', true)
        )
      SQL
    end

    puts "✓ 完成！共处理 #{TABLES_WITH_DATA_VERSION.count} 个表"
  end
end
