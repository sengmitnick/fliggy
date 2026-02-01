# frozen_string_literal: true

# z_hotel_packages_associations_v1 数据包
# 更新酒店套餐与酒店的关联关系
#
# 用途：
# - 在所有酒店数据包加载完成后，更新 HotelPackage 的 hotel_id
# - 按品牌和城市匹配对应的酒店
# - 统计关联成功和失败的情况
#
# 加载方式：
# rake validator:reset_baseline
#
# 说明：
# - 文件名以 z_ 开头，确保在所有酒店数据包之后加载
# - 使用缓存避免重复查询同一品牌+城市组合

puts "正在更新酒店套餐关联..."

# 获取所有需要关联的套餐（hotel_id 为 nil 的）
created_packages = HotelPackage.where(data_version: 0, hotel_id: nil)

if created_packages.empty?
  puts "  → 没有需要更新关联的套餐"
else
  # 按品牌和城市分组更新
  hotel_associations = {}
  updated_count = 0
  missing_hotels = []
  
  created_packages.each do |package|
    # 查找匹配的酒店（按品牌和城市匹配）
    # 使用缓存避免重复查询
    cache_key = "#{package.brand_name}|#{package.city}"
    
    unless hotel_associations.key?(cache_key)
      # 查找该品牌+城市的第一个酒店
      hotel = Hotel.find_by(brand: package.brand_name, city: package.city, data_version: 0)
      hotel_associations[cache_key] = hotel&.id
    end
    
    hotel_id = hotel_associations[cache_key]
    
    if hotel_id
      package.update_column(:hotel_id, hotel_id)
      updated_count += 1
    else
      missing_hotels << "#{package.brand_name} (#{package.city})"
    end
  end
  
  puts "✅ 已更新 #{updated_count} 个套餐的酒店关联"
  
  # 统计关联情况
  packages_with_hotel = HotelPackage.where(data_version: 0).where.not(hotel_id: nil).count
  packages_without_hotel = HotelPackage.where(data_version: 0, hotel_id: nil).count
  
  puts "   - 已关联酒店: #{packages_with_hotel} 个"
  
  if packages_without_hotel > 0
    puts "   - 未关联酒店: #{packages_without_hotel} 个"
    puts "\n   ⚠️  以下品牌+城市组合未找到匹配的酒店:"
    missing_hotels.uniq.each do |missing|
      puts "      → #{missing}"
    end
  end
end

puts "✓ z_hotel_packages_associations_v1 数据包加载完成"
