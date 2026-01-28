# frozen_string_literal: true

# live_products_v1 数据包
# 直播间商品关联数据
#
# 用途：
# - 为"旅游环境01 直播间"关联旅游产品和酒店套餐
#
# 加载方式：
# rake validator:reset_baseline

puts "正在加载 live_products_v1 数据包..."

# ==================== 创建直播间商品关联 ====================

# 获取深圳的旅游产品（使用 TourGroupProduct）
tour_group_product = TourGroupProduct.where("destination LIKE '%深圳%'")
                                    .where("title LIKE '%欢乐谷%' OR title LIKE '%一日游%'")
                                    .first

# 如果没有找到，就取深圳的第一个产品
tour_group_product ||= TourGroupProduct.where("destination LIKE '%深圳%'").first

# 获取酒店套餐
hotel_package = HotelPackage.first

if tour_group_product && hotel_package
  # 清理旧的直播间商品数据
  LiveProduct.where(live_room_name: "旅游环境01 直播间").destroy_all
  
  # 创建直播间商品关联
  live_products_data = [
    {
      productable_type: "TourGroupProduct",
      productable_id: tour_group_product.id,
      position: 0,
      live_room_name: "旅游环境01 直播间",
      created_at: Time.current,
      updated_at: Time.current
    },
    {
      productable_type: "HotelPackage",
      productable_id: hotel_package.id,
      position: 1,
      live_room_name: "旅游环境01 直播间",
      created_at: Time.current,
      updated_at: Time.current
    }
  ]
  
  LiveProduct.insert_all(live_products_data)
  
  puts "     已关联 #{live_products_data.size} 个商品到直播间"
  puts "       - 旅游产品: #{tour_group_product.title}"
  puts "       - 酒店套餐: #{hotel_package.title}"
else
  puts "     ⚠️  无法关联商品：TourGroupProduct=#{tour_group_product.present?}, HotelPackage=#{hotel_package.present?}"
end

puts "✓ 数据包加载完成"
