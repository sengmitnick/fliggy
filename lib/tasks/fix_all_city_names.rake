# frozen_string_literal: true

namespace :db do
  desc "Remove '市' suffix from all city-related data to unify with train data format"
  task fix_all_city_names: :environment do
    puts "开始统一所有城市名称数据..."
    
    total_fixed = 0
    errors = []
    
    # 1. 修复 City 模型
    puts "\n1. 修复 City 数据..."
    cities_to_fix = City.where("name LIKE '%市'")
    cities_to_fix.each do |city|
      old_name = city.name
      new_name = old_name.gsub(/市$/, '')
      begin
        city.update!(name: new_name)
        puts "  ✓ #{old_name} → #{new_name}"
        total_fixed += 1
      rescue => e
        errors << "  ✗ City #{old_name}: #{e.message}"
      end
    end
    puts "  完成: #{cities_to_fix.count} 条记录"
    
    # 2. 修复 Flight 模型
    puts "\n2. 修复 Flight 数据..."
    flight_count = 0
    
    # 修复出发城市
    ['深圳市', '上海市', '北京市', '广州市', '杭州市', '成都市', '西安市', '南京市', '武汉市', '重庆市', '天津市'].each do |old_city|
      new_city = old_city.gsub(/市$/, '')
      count = Flight.where(departure_city: old_city).update_all(departure_city: new_city)
      if count > 0
        puts "  ✓ 出发城市: #{old_city} → #{new_city} (#{count} 条)"
        flight_count += count
        total_fixed += count
      end
    end
    
    # 修复目的城市
    ['深圳市', '上海市', '北京市', '广州市', '杭州市', '成都市', '西安市', '南京市', '武汉市', '重庆市', '天津市'].each do |old_city|
      new_city = old_city.gsub(/市$/, '')
      count = Flight.where(destination_city: old_city).update_all(destination_city: new_city)
      if count > 0
        puts "  ✓ 目的城市: #{old_city} → #{new_city} (#{count} 条)"
        flight_count += count
        total_fixed += count
      end
    end
    puts "  完成: #{flight_count} 条 Flight 记录"
    
    # 3. 修复 Hotel 模型
    puts "\n3. 修复 Hotel 数据..."
    hotel_count = 0
    ['深圳市', '上海市', '北京市', '广州市', '杭州市', '成都市', '西安市', '南京市', '武汉市', '重庆市', '天津市'].each do |old_city|
      new_city = old_city.gsub(/市$/, '')
      count = Hotel.where(city: old_city).update_all(city: new_city)
      if count > 0
        puts "  ✓ #{old_city} → #{new_city} (#{count} 家酒店)"
        hotel_count += count
        total_fixed += count
      end
    end
    puts "  完成: #{hotel_count} 条 Hotel 记录"
    
    # 4. 修复 Address 模型（province 和 city 字段）
    if defined?(Address)
      puts "\n4. 修复 Address 数据..."
      address_count = 0
      
      # 修复 province 字段
      ['北京市', '上海市', '天津市', '重庆市'].each do |old_prov|
        new_prov = old_prov.gsub(/市$/, '')
        count = Address.where(province: old_prov).update_all(province: new_prov)
        if count > 0
          puts "  ✓ province: #{old_prov} → #{new_prov} (#{count} 条)"
          address_count += count
          total_fixed += count
        end
      end
      
      # 修复 city 字段
      ['深圳市', '上海市', '北京市', '广州市', '杭州市', '成都市', '西安市', '南京市', '武汉市', '重庆市', '天津市'].each do |old_city|
        new_city = old_city.gsub(/市$/, '')
        count = Address.where(city: old_city).update_all(city: new_city)
        if count > 0
          puts "  ✓ city: #{old_city} → #{new_city} (#{count} 条)"
          address_count += count
          total_fixed += count
        end
      end
      puts "  完成: #{address_count} 条 Address 记录"
    end
    
    # 5. 修复 Booking 模型（如果有城市相关字段）
    if defined?(Booking) && Booking.column_names.include?('departure_city')
      puts "\n5. 修复 Booking 数据..."
      booking_count = 0
      ['深圳市', '上海市', '北京市', '广州市', '杭州市', '成都市', '西安市', '南京市', '武汉市', '重庆市', '天津市'].each do |old_city|
        new_city = old_city.gsub(/市$/, '')
        count = Booking.where(departure_city: old_city).update_all(departure_city: new_city)
        if count > 0
          puts "  ✓ #{old_city} → #{new_city} (#{count} 条)"
          booking_count += count
          total_fixed += count
        end
      end
      puts "  完成: #{booking_count} 条 Booking 记录"
    end
    
    puts "\n" + "="*60
    puts "✅ 城市名称统一完成！"
    puts "  总计修复: #{total_fixed} 条记录"
    puts "  失败: #{errors.count} 条"
    
    if errors.any?
      puts "\n失败详情:"
      errors.each { |error| puts error }
    end
    
    # 验证结果
    puts "\n" + "="*60
    puts "验证结果:"
    puts "  Flight: 深圳->北京 #{Flight.where(departure_city: '深圳', destination_city: '北京').count} 条"
    puts "  Flight: 上海->深圳 #{Flight.where(departure_city: '上海', destination_city: '深圳').count} 条"
    puts "  Hotel: 深圳 #{Hotel.where(city: '深圳').count} 家"
    puts "  Hotel: 北京 #{Hotel.where(city: '北京').count} 家"
    puts "  Train: 北京->天津 #{Train.where(departure_city: '北京', arrival_city: '天津').count} 条"
    puts "="*60
  end
end
