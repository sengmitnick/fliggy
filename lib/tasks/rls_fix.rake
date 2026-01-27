# frozen_string_literal: true

namespace :rls do
  desc "强制启用所有业务表的 RLS 策略（修复多会话隔离问题）"
  task force_enable: :environment do
    # 如果提供了 ADMIN_DB_URL，使用超级管理员连接
    if ENV['ADMIN_DB_URL'].present?
      puts "  → 使用 ADMIN_DB_URL 连接（超级管理员）"
      ActiveRecord::Base.establish_connection(ENV['ADMIN_DB_URL'])
    end

    excluded_tables = %w[
      schema_migrations ar_internal_metadata active_storage_blobs
      active_storage_attachments active_storage_variant_records
      good_jobs good_job_batches good_job_executions good_job_processes good_job_settings
      solid_cable_messages administrators sessions admin_oplogs
      validator_executions friendly_id_slugs
    ]

    all_tables = ActiveRecord::Base.connection.tables
    business_tables = (all_tables - excluded_tables).sort

    puts "\n" + "=" * 80
    puts "强制启用所有业务表的 RLS 策略（FORCE ROW LEVEL SECURITY）"
    puts "=" * 80
    puts "\n这将确保多会话数据隔离功能正确工作。\n\n"

    success_count = 0
    failure_count = 0

    business_tables.each do |table|
      begin
        ActiveRecord::Base.connection.execute("ALTER TABLE #{table} FORCE ROW LEVEL SECURITY")
        puts "  ✓ #{table}"
        success_count += 1
      rescue => e
        puts "  ✗ #{table}: #{e.message}"
        failure_count += 1
      end
    end

    # 恢复默认连接
    if ENV['ADMIN_DB_URL'].present?
      ActiveRecord::Base.establish_connection(Rails.env.to_sym)
    end

    puts "\n" + "=" * 80
    puts "完成！成功: #{success_count}，失败: #{failure_count}"
    puts "=" * 80

    # 验证
    puts "\n验证 RLS 状态..."
    check = ActiveRecord::Base.connection.execute("
      SELECT tablename, rowsecurity, relforcerowsecurity
      FROM pg_tables t
      JOIN pg_class c ON c.relname = t.tablename
      WHERE schemaname = 'public'
      AND tablename IN ('hotel_bookings', 'flight_offers', 'train_bookings')
    ").to_a

    check.each do |t|
      force_status = t['relforcerowsecurity'] == 't' ? '✅ FORCED' : '❌ NOT FORCED'
      puts "  #{t['tablename']}: rowsecurity=#{t['rowsecurity']}, #{force_status}"
    end
    puts
  end

  desc "检查 RLS 状态"
  task check_status: :environment do
    puts "\n" + "=" * 80
    puts "检查 RLS 状态"
    puts "=" * 80

    # 检查数据库用户
    current_user = ActiveRecord::Base.connection.execute(
      "SELECT current_user, usesuper FROM pg_user WHERE usename = current_user"
    ).first
    puts "\n当前数据库用户: #{current_user['current_user']}"
    puts "是否超级用户: #{current_user['usesuper']}"

    # 检查 RLS 策略数量
    policy_count = ActiveRecord::Base.connection.execute(
      "SELECT COUNT(*) as count FROM pg_policies WHERE schemaname = 'public'"
    ).first['count']
    puts "\nRLS 策略数量: #{policy_count}"

    # 检查关键表的 RLS 状态
    puts "\n关键业务表的 RLS 状态:"
    check_tables = %w[hotel_bookings flight_offers train_bookings users]

    check_tables.each do |table|
      result = ActiveRecord::Base.connection.execute("
        SELECT t.tablename, t.rowsecurity, c.relforcerowsecurity
        FROM pg_tables t
        JOIN pg_class c ON c.relname = t.tablename
        WHERE t.schemaname = 'public' AND t.tablename = '#{table}'
      ").first

      if result
        rls_status = result['rowsecurity'] == 't' ? '✅' : '❌'
        force_status = result['relforcerowsecurity'] == 't' ? '✅ FORCED' : '❌ NOT FORCED'
        puts "  #{rls_status} #{table}: rowsecurity=#{result['rowsecurity']}, #{force_status}"
      else
        puts "  ❓ #{table}: 表不存在"
      end
    end

    puts "\n" + "=" * 80
  end

  desc "测试多会话隔离功能"
  task test_isolation: :environment do
    puts "\n" + "=" * 80
    puts "测试多会话数据隔离功能"
    puts "=" * 80

    # 创建测试用户
    user = User.first || User.create!(
      name: 'Test User',
      email: 'test@rls.com',
      password: 'password123',
      password_confirmation: 'password123'
    )
    puts "\n✓ 测试用户: #{user.email}"

    # 创建两个会话
    session_1 = SecureRandom.uuid
    session_2 = SecureRandom.uuid
    data_version_1 = session_1.hash.abs
    data_version_2 = session_2.hash.abs

    puts "\n会话配置:"
    puts "  Session 1: #{session_1} → data_version=#{data_version_1}"
    puts "  Session 2: #{session_2} → data_version=#{data_version_2}"

    # 创建验证执行记录
    ValidatorExecution.find_or_create_by!(execution_id: session_1) do |e|
      e.user_id = user.id
      e.state = { data: { data_version: data_version_1 } }
      e.is_active = true
    end

    ValidatorExecution.find_or_create_by!(execution_id: session_2) do |e|
      e.user_id = user.id
      e.state = { data: { data_version: data_version_2 } }
      e.is_active = true
    end

    # 清理测试数据
    ActiveRecord::Base.connection.execute("DELETE FROM hotel_bookings WHERE guest_name LIKE 'RLS Test%'")

    # Session 1 创建数据
    ActiveRecord::Base.connection.execute("SET app.data_version = '#{data_version_1}'")
    hotel = Hotel.first
    if hotel && hotel.hotel_rooms.any?
      HotelBooking.create!(
        hotel_id: hotel.id,
        hotel_room_id: hotel.hotel_rooms.first.id,
        user_id: user.id,
        check_in_date: Date.today,
        check_out_date: Date.today + 1,
        guest_name: 'RLS Test Session 1',
        guest_phone: '13800138001',
        rooms_count: 1,
        adults_count: 2,
        children_count: 0,
        payment_method: '花呗',
        status: 'pending',
        total_price: 100,
        data_version: data_version_1
      )
      puts "\n✓ Session 1 创建了酒店预订"
    end

    # Session 2 创建数据
    ActiveRecord::Base.connection.execute("SET app.data_version = '#{data_version_2}'")
    if hotel && hotel.hotel_rooms.any?
      HotelBooking.create!(
        hotel_id: hotel.id,
        hotel_room_id: hotel.hotel_rooms.first.id,
        user_id: user.id,
        check_in_date: Date.today,
        check_out_date: Date.today + 1,
        guest_name: 'RLS Test Session 2',
        guest_phone: '13800138002',
        rooms_count: 1,
        adults_count: 1,
        children_count: 0,
        payment_method: '花呗分期',
        status: 'pending',
        total_price: 200,
        data_version: data_version_2
      )
      puts "✓ Session 2 创建了酒店预订"
    end

    # 验证隔离
    puts "\n验证数据隔离:"

    # Session 1 视图
    ActiveRecord::Base.connection.execute("SET app.data_version = '#{data_version_1}'")
    guests_1 = HotelBooking.where("guest_name LIKE 'RLS Test%'").pluck(:guest_name)
    puts "  Session 1 视图: #{guests_1.inspect}"

    # Session 2 视图
    ActiveRecord::Base.connection.execute("SET app.data_version = '#{data_version_2}'")
    guests_2 = HotelBooking.where("guest_name LIKE 'RLS Test%'").pluck(:guest_name)
    puts "  Session 2 视图: #{guests_2.inspect}"

    # 判断结果
    puts "\n" + "=" * 80
    if guests_1 == ['RLS Test Session 1'] && guests_2 == ['RLS Test Session 2']
      puts "✅ 多会话隔离测试通过！"
      puts "   • Session 1 只能看到自己的数据"
      puts "   • Session 2 只能看到自己的数据"
    else
      puts "❌ 多会话隔离测试失败！"
      puts "   • Session 1: #{guests_1.inspect}"
      puts "   • Session 2: #{guests_2.inspect}"
      puts "\n请运行: rake rls:force_enable"
    end
    puts "=" * 80

    # 清理测试数据
    ActiveRecord::Base.connection.execute("DELETE FROM hotel_bookings WHERE guest_name LIKE 'RLS Test%'")
    puts "\n✓ 测试数据已清理"
  end
end
