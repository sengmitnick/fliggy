# Shenzhen hotels seed data
puts "Creating Shenzhen hotels..."

shenzhen_regions = {
  '南山区' => ['科技园', '深圳湾', '蛇口', '南山中心'],
  '福田区' => ['福田中心', '会展中心', '车公庙', '华强北'],
  '罗湖区' => ['东门', '国贸', '火车站', '笋岗'],
  '宝安区' => ['宝安中心', '西乡', '机场', '新安'],
  '龙岗区' => ['龙岗中心', '布吉', '坂田', '平湖'],
  '龙华区' => ['龙华中心', '民治', '大浪', '观澜']
}

brands = ['如家', '汉庭', '锦江之星', '7天', '维也纳', '全季', '桔子', '亚朵', '希尔顿', '万豪', '喜来登', '凯悦']
hotel_types = ['酒店', '商务酒店', '精品酒店', '快捷酒店']

hotel_images = [
  'https://images.unsplash.com/photo-1566073771259-6a8506099945',
  'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb',
  'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4',
  'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa',
  'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b'
]

# Ensure at least one user exists for reviews
user = User.first || User.create!(
  email: "demo@example.com",
  password_digest: BCrypt::Password.create("password123")
)

created_count = 0

shenzhen_regions.each do |district, areas|
  areas.each do |area|
    # Create 3-5 hotels per area
    rand(3..5).times do |i|
      brand = brands.sample
      hotel_type_suffix = hotel_types.sample
      star_level = rand(3..5)
      price = case star_level
      when 5
        rand(400..800)
      when 4
        rand(200..400)
      else
        rand(100..200)
      end
      
      hotel = Hotel.create!(
        name: "深圳#{area}#{brand}#{hotel_type_suffix}",
        city: '深圳',
        address: "广东省深圳市#{district}#{area}#{rand(1..999)}号",
        price: price,
        rating: rand(40..50) / 10.0,
        star_level: star_level,
        hotel_type: 'hotel',
        region: area,
        is_featured: i == 0 && rand < 0.3,
        is_domestic: true,
        brand: brand,
        display_order: created_count,
        distance: rand(100..5000)
      )
      
      # Set image URL
      hotel.update(image_url: hotel_images.sample)
      
      # Create hotel rooms
      room_types = ['标准双人间', '大床房', '豪华套房', '商务大床房']
      rand(2..4).times do
        room_type = room_types.sample
        room_price = hotel.price + rand(-50..100)
        
        HotelRoom.create!(
          hotel: hotel,
          room_type: room_type,
          price: room_price > 0 ? room_price : hotel.price,
          available_rooms: rand(5..20),
          room_category: 'overnight'
        )
      end
      
      # Create facilities
      facilities_data = [
        { name: '免费WiFi', icon: 'wifi', description: '全酒店覆盖高速无线网络', category: '网络' },
        { name: '停车场', icon: 'local_parking', description: '提供免费停车服务', category: '停车' },
        { name: '餐厅', icon: 'restaurant', description: '酒店内设中西餐厅', category: '餐饮' },
        { name: '健身房', icon: 'fitness_center', description: '24小时开放健身设施', category: '健身' },
        { name: '游泳池', icon: 'pool', description: '室内恒温游泳池', category: '休闲' },
        { name: '会议室', icon: 'meeting_room', description: '提供商务会议服务', category: '商务' }
      ]
      
      facilities_data.sample(rand(3..5)).each do |facility|
        HotelFacility.create!(
          hotel: hotel,
          name: facility[:name],
          icon: facility[:icon],
          description: facility[:description],
          category: facility[:category]
        )
      end
      
      # Create hotel policy
      HotelPolicy.create!(
        hotel: hotel,
        check_in_time: "14:00后",
        check_out_time: "12:00前",
        pet_policy: "暂不支持携带宠物",
        breakfast_type: star_level >= 4 ? "含早餐" : "不含早餐",
        breakfast_hours: "每天07:00-10:00",
        breakfast_price: star_level >= 4 ? 0 : rand(20..50),
        payment_methods: ["银联", "支付宝", "微信支付"]
      )
      
      # Create reviews
      rand(2..4).times do
        HotelReview.create!(
          hotel: hotel,
          user: user,
          rating: rand(40..50) / 10.0,
          comment: "酒店位置优越，服务周到，房间舒适干净。#{area}的好选择！"
        )
      end
      
      created_count += 1
    end
  end
end

puts "Created #{created_count} hotels in Shenzhen across #{shenzhen_regions.keys.size} districts"
