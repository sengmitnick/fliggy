class HotelGeneratorService < ApplicationService
  def self.generate_batch(count)
    generated_count = 0
    
    cities = [
      "深圳", "上海", "北京", "广州", "杭州",
      "成都", "西安", "南京", "武汉", "重庆"
    ]
    
    hotel_names = [
      { prefix: "", suffix: "希尔顿酒店" },
      { prefix: "", suffix: "喜来登酒店" },
      { prefix: "", suffix: "万豪酒店" },
      { prefix: "", suffix: "香格里拉大酒店" },
      { prefix: "", suffix: "洲际酒店" },
      { prefix: "", suffix: "凯悦酒店" },
      { prefix: "", suffix: "丽思卡尔顿酒店" },
      { prefix: "", suffix: "威斯汀酒店" },
      { prefix: "", suffix: "皇冠假日酒店" },
      { prefix: "", suffix: "万丽酒店" },
      { prefix: "", suffix: "温德姆酒店" },
      { prefix: "", suffix: "君悦酒店" },
      { prefix: "", suffix: "索菲特酒店" },
      { prefix: "", suffix: "雅高酒店" },
      { prefix: "", suffix: "铂尔曼酒店" },
      { prefix: "", suffix: "康莱德酒店" },
      { prefix: "", suffix: "悦榕庄" },
      { prefix: "", suffix: "安缦酒店" },
      { prefix: "", suffix: "柏悦酒店" },
      { prefix: "", suffix: "瑰丽酒店" }
    ]
    
    addresses = [
      "中心大道", "商业街", "火车站附近", "机场路",
      "市中心", "老城区", "新区", "开发区",
      "滨海路", "山景路", "湖畔大道", "CBD核心区"
    ]
    
    hotel_images = [
      "https://images.unsplash.com/photo-1566073771-7e72bca2f686?w=800&q=80",
      "https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=800&q=80",
      "https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=800&q=80",
      "https://images.unsplash.com/photo-1571003123894-1f0594d2b5d9?w=800&q=80",
      "https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=800&q=80",
      "https://images.unsplash.com/photo-1549294413-26f195200c16?w=800&q=80",
      "https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=800&q=80",
      "https://images.unsplash.com/photo-1584132967334-10e028bd69f7?w=800&q=80",
      "https://images.unsplash.com/photo-1517840901100-8179e982acb7?w=800&q=80",
      "https://images.unsplash.com/photo-1564501049412-61c2a3083791?w=800&q=80"
    ]
    
    count.times do |i|
      city = cities.sample
      hotel_name_template = hotel_names.sample
      hotel_name = "#{city}#{hotel_name_template[:prefix]}#{hotel_name_template[:suffix]}"
      star_level = [3, 4, 5].sample
      base_price = case star_level
                   when 5 then rand(800..2000)
                   when 4 then rand(400..800)
                   else rand(200..400)
                   end
      
      hotel = Hotel.create!(
        name: hotel_name,
        city: city,
        address: "#{addresses.sample}#{rand(1..999)}号",
        rating: (4.0 + rand * 1.0).round(1),
        price: base_price,
        original_price: (base_price * (1.1 + rand * 0.3)).round,
        distance: "#{(rand * 5).round(1)}km",
        features: ["免费WiFi", "停车场", "健身房", "游泳池", "餐厅", "会议室", "接送服务"].sample(rand(3..5)),
        star_level: star_level,
        is_featured: [true, false].sample,
        display_order: Hotel.maximum(:display_order).to_i + i + 1,
        image_url: hotel_images.sample
      )
      
      # 创建酒店政策
      HotelPolicy.create!(
        hotel: hotel,
        check_in_time: ["14:00", "15:00", "16:00"].sample,
        check_out_time: ["12:00", "11:00", "13:00"].sample,
        pet_policy: ["不可携带宠物", "可携带小型宠物", "可携带宠物(需额外收费)"].sample,
        breakfast_type: ["自助早餐", "中西式早餐", "不含早餐"].sample,
        breakfast_hours: "06:30-10:00",
        breakfast_price: rand(40..100),
        payment_methods: ["现金", "支付宝", "微信支付", "银行卡", "信用卡"]
      )
      
      # 创建酒店设施
      facilities = [
        { name: "免费WiFi", icon: "wifi", description: "全酒店覆盖", category: "基础设施" },
        { name: "停车场", icon: "local_parking", description: "免费停车位", category: "基础设施" },
        { name: "健身房", icon: "fitness_center", description: "24小时开放", category: "休闲娱乐" },
        { name: "游泳池", icon: "pool", description: "室内恒温泳池", category: "休闲娱乐" },
        { name: "餐厅", icon: "restaurant", description: "中西餐厅", category: "餐饮服务" },
        { name: "会议室", icon: "meeting_room", description: "多功能会议室", category: "商务服务" },
        { name: "洗衣服务", icon: "local_laundry_service", description: "24小时洗衣服务", category: "客房服务" },
        { name: "行李寄存", icon: "luggage", description: "免费行李寄存", category: "客房服务" }
      ]
      facilities.sample(rand(3..5)).each do |facility|
        HotelFacility.create!(hotel: hotel, **facility)
      end
      
      # 创建房型
      room_types = [
        { room_type: "标准双床房", bed_type: "双床", area: rand(25..35), max_guests: 2 },
        { room_type: "标准大床房", bed_type: "大床", area: rand(25..35), max_guests: 2 },
        { room_type: "豪华套房", bed_type: "大床", area: rand(45..65), max_guests: 3 },
        { room_type: "行政套房", bed_type: "大床", area: rand(55..75), max_guests: 4 }
      ]
      room_types.sample(rand(2..4)).each do |room_type_data|
        room_price = (base_price * (0.8 + rand * 0.4)).round
        HotelRoom.create!(
          hotel: hotel,
          room_type: room_type_data[:room_type],
          bed_type: room_type_data[:bed_type],
          price: room_price,
          original_price: (room_price * 1.2).round,
          area: room_type_data[:area],
          max_guests: room_type_data[:max_guests],
          has_window: true,
          available_rooms: rand(5..20)
        )
        
        # 为每个房型创建详细的房间信息
        Room.create!(
          hotel: hotel,
          name: room_type_data[:room_type],
          size: "#{room_type_data[:area]}㎡",
          bed_type: room_type_data[:bed_type],
          price: room_price,
          original_price: (room_price * 1.2).round,
          amenities: ["免费WiFi", "空调", "电视", "热水器", "吹风机", "拖鞋"].sample(rand(4..6)),
          breakfast_included: [true, false].sample,
          cancellation_policy: "入住前24小时可免费取消"
        )
      end
      
      # 创建用户评价
      review_comments = [
        "酒店位置很好，服务态度很棒",
        "房间干净整洁，设施齐全",
        "性价比很高，下次还会入住",
        "环境优美，很安静，适合休息",
        "早餐丰富，味道不错",
        "前台服务很专业，办理入住很快",
        "房间很大，床很舒服",
        "交通便利，周边设施齐全"
      ]
      rand(3..8).times do
        HotelReview.create!(
          hotel: hotel,
          user_id: User.pluck(:id).sample || 1,
          rating: (4.0 + rand * 1.0).round(1),
          comment: review_comments.sample,
          helpful_count: rand(0..50)
        )
      end
      
      generated_count += 1
    end
    
    generated_count
  end
end
