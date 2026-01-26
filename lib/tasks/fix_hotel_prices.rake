# frozen_string_literal: true

namespace :hotels do
  desc "Fix hotel prices to match minimum room price"
  task fix_prices: :environment do
    puts "正在修复酒店价格..."
    
    fixed_count = 0
    skipped_count = 0
    
    Hotel.find_each do |hotel|
      min_room_price = hotel.hotel_rooms.minimum(:price)
      
      if min_room_price.nil?
        puts "  跳过: #{hotel.name} (ID: #{hotel.id}) - 没有房间数据"
        skipped_count += 1
        next
      end
      
      if hotel.price != min_room_price
        old_price = hotel.price
        hotel.update_column(:price, min_room_price)
        puts "  修复: #{hotel.name} (ID: #{hotel.id}) - #{old_price} → #{min_room_price}"
        fixed_count += 1
      end
    end
    
    puts "\n修复完成!"
    puts "  修复: #{fixed_count} 个酒店"
    puts "  跳过: #{skipped_count} 个酒店"
  end
  
  desc "Check hotels with price mismatch"
  task check_mismatch: :environment do
    puts "检查价格不匹配的酒店...\n"
    
    mismatch_count = 0
    
    Hotel.find_each do |hotel|
      min_room_price = hotel.hotel_rooms.minimum(:price)
      
      next if min_room_price.nil?
      next if hotel.price == min_room_price
      
      puts "酒店: #{hotel.name} (ID: #{hotel.id})"
      puts "  hotel.price: #{hotel.price}"
      puts "  最低房间价: #{min_room_price}"
      puts "  房间列表:"
      hotel.hotel_rooms.each do |room|
        puts "    - #{room.room_type}: #{room.price}"
      end
      puts ""
      
      mismatch_count += 1
    end
    
    puts "发现 #{mismatch_count} 个价格不匹配的酒店"
  end
end
