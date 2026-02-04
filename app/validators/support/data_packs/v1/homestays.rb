# frozen_string_literal: true

# 民宿补充数据包 v1 - 添加杭州西湖区月租房和成都宽窄巷子民宿
# 补充长租民宿和网红民宿数据
#
# 用途：
# - 支持 v108 验证器（杭州西湖区月租民宿）
# - 支持 v109 验证器（成都宽窄巷子网红民宿）
#
# 加载方式：
# rake validator:reset_baseline

require_relative '../../../../../app/helpers/image_seed_helper'

puts "正在加载 homestays_supplement_v1 数据包（杭州月租+成都网红民宿）..."

timestamp = Time.current

# ==================== 杭州西湖区月租民宿 ====================
hangzhou_homestays_data = []

# 创建 3 家杭州西湖区的民宿，包含月租房型
['西湖雅居', '西溪小筑', '灵隐静舍'].each_with_index do |name, index|
  hangzhou_homestays_data << {
    name: "杭州#{name}",
    brand: "",
    city: "杭州",
    address: "杭州西湖区#{['西湖', '西溪湿地', '灵隐寺'].sample}附近#{rand(10..100)}号",
    rating: (4.2 + rand * 0.6).round(1),
    price: 1800 + index * 300,  # 价格递增：1800, 2100, 2400
    original_price: (2000 + index * 350).round(0),
    distance: "#{rand(1..5)}.#{rand(0..9)}km",
    features: ["免费WiFi", "厨房", "洗衣机", "独立卫浴", "阳台"],
    star_level: nil,
    is_featured: false,
    display_order: 9000 + index,
    hotel_type: 'homestay',
    is_domestic: true,
    region: '国内',
    image_url: ImageSeedHelper.random_image_from_category(:hotels),
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
end

Hotel.insert_all(hangzhou_homestays_data)
hangzhou_homestays = Hotel.where(city: '杭州', hotel_type: 'homestay', data_version: 0)
                           .where("address LIKE ?", "%西湖区%")

# 为杭州民宿创建月租房型
hangzhou_rooms_data = []
hangzhou_homestays.each do |hotel|
  # 每个民宿添加 2-3 个月租房型
  room_types = ['一居室', '两居室', '三居室'].sample(rand(2..3))
  room_types.each_with_index do |room_type, index|
    hangzhou_rooms_data << {
      hotel_id: hotel.id,
      room_type: "#{room_type}月租房",
      room_category: 'monthly',  # 月租房标识
      bed_type: room_type.include?('一') ? 'queen' : 'king',
      max_guests: room_type.include?('一') ? 2 : (room_type.include?('两') ? 4 : 6),
      area: rand(30..80),
      price: hotel.price + index * 200,  # 房型价格基于酒店基础价格
      original_price: (hotel.original_price + index * 250).round(0),
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    }
  end
end

HotelRoom.insert_all(hangzhou_rooms_data) if hangzhou_rooms_data.any?

# ==================== 成都宽窄巷子网红民宿 ====================
chengdu_homestays_data = []

# 创建 4 家成都宽窄巷子的民宿，评分都>=4.5，销量不同
homestay_configs = [
  { name: '宽巷客栈', rating: 4.8, sales: 520 },
  { name: '窄巷雅舍', rating: 4.7, sales: 380 },
  { name: '巷子里', rating: 4.6, sales: 290 },
  { name: '锦里小院', rating: 4.5, sales: 150 }
]

homestay_configs.each_with_index do |config, index|
  chengdu_homestays_data << {
    name: "成都#{config[:name]}",
    brand: "",
    city: "成都",
    address: "成都宽窄巷子#{['宽巷子', '窄巷子', '井巷子'].sample}#{rand(10..80)}号",
    rating: config[:rating],
    price: rand(180..350),
    original_price: rand(220..420),
    distance: "#{rand(1..3)}.#{rand(0..9)}km",
    features: ["免费WiFi", "厨房", "洗衣机", "独立卫浴", "川西风格装修"],
    star_level: nil,
    is_featured: index == 0,  # 销量最高的设为精选
    display_order: 9100 + index,
    hotel_type: 'homestay',
    is_domestic: true,
    region: '国内',
    image_url: ImageSeedHelper.random_image_from_category(:hotels),
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
end

Hotel.insert_all(chengdu_homestays_data)
chengdu_homestays = Hotel.where(city: '成都', hotel_type: 'homestay', data_version: 0)
                          .where("address LIKE ?", "%宽窄巷子%")

# 为成都民宿创建整晚房型（overnight）
chengdu_rooms_data = []
chengdu_homestays.each do |hotel|
  # 每个民宿添加 2-3 个整晚房型
  room_types = ['大床房', '双床房', '榻榻米房'].sample(rand(2..3))
  room_types.each_with_index do |room_type, index|
    chengdu_rooms_data << {
      hotel_id: hotel.id,
      room_type: room_type,
      room_category: 'overnight',  # 整晚房标识
      bed_type: room_type == '双床房' ? 'twin' : 'queen',
      max_guests: 2,
      area: rand(20..40),
      price: hotel.price + index * 30,
      original_price: (hotel.original_price + index * 40).round(0),
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    }
  end
end

HotelRoom.insert_all(chengdu_rooms_data) if chengdu_rooms_data.any?

puts "✓ 数据包加载完成"
puts "  - 杭州西湖区月租民宿: #{hangzhou_homestays.count} 家，月租房型: #{hangzhou_rooms_data.size} 个"
puts "  - 成都宽窄巷子网红民宿: #{chengdu_homestays.count} 家，整晚房型: #{chengdu_rooms_data.size} 个"
