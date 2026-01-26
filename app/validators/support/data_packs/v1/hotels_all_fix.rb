# frozen_string_literal: true

# 修复酒店价格 - 在数据包加载后运行
# 确保 hotel.price = minimum(hotel_rooms.price)

puts "🔧 同步酒店价格为实际最低房价..."

fixed_count = 0
Hotel.find_each do |hotel|
  min_room_price = hotel.hotel_rooms.minimum(:price)
  
  next if min_room_price.nil?
  next if hotel.price == min_room_price
  
  hotel.update_column(:price, min_room_price)
  fixed_count += 1
end

puts "✓ 已同步 #{fixed_count} 家酒店价格"
puts "✅ 酒店价格同步完成！"
