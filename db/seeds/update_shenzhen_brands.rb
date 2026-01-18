# 更新深圳市酒店品牌，使其与其他城市一致
puts "正在更新深圳市酒店品牌..."

# 统一的品牌列表（与其他城市一致）
unified_brands = [
  "希尔顿", "希尔顿欢朋", "凯悦", "万达酒店", 
  "君澜", "不棉花", "万豪", "亚朵", "维也纳"
]

# 获取深圳市所有酒店
shenzhen_hotels = Hotel.where(city: '深圳市')

puts "找到 #{shenzhen_hotels.count} 家深圳市酒店"

# 为每家酒店随机分配统一品牌列表中的品牌
shenzhen_hotels.each do |hotel|
  old_brand = hotel.brand
  new_brand = unified_brands.sample
  
  hotel.update!(brand: new_brand)
  puts "更新酒店: #{hotel.name} - #{old_brand} -> #{new_brand}"
end

puts "\n深圳市酒店品牌更新完成！"
puts "\n更新后的品牌统计:"
Hotel.where(city: '深圳市').group(:brand).count.each do |brand, count|
  puts "  #{brand}: #{count}家"
end
