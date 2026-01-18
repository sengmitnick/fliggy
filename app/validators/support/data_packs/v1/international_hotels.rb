# International Hotels Seed Data
puts "Creating international hotels..."

# International cities with their countries
international_cities = {
  # 东南亚
  '曼谷' => { country: '泰国', is_domestic: false },
  '普吉岛' => { country: '泰国', is_domestic: false },
  '新加坡' => { country: '新加坡', is_domestic: false },
  '清迈' => { country: '泰国', is_domestic: false },
  '亚庇' => { country: '马来西亚', is_domestic: false },
  '芭堤雅' => { country: '泰国', is_domestic: false },
  '吉隆坡' => { country: '马来西亚', is_domestic: false },
  '济州岛' => { country: '韩国', is_domestic: false },
  '苏梅岛' => { country: '泰国', is_domestic: false },
  '甲米' => { country: '泰国', is_domestic: false },
  
  # 日韩
  '首尔' => { country: '韩国', is_domestic: false },
  '东京' => { country: '日本', is_domestic: false },
  '大阪' => { country: '日本', is_domestic: false },
  
  # 欧洲
  '伦敦' => { country: '英国', is_domestic: false },
  '巴黎' => { country: '法国', is_domestic: false },
  '罗马' => { country: '意大利', is_domestic: false },
  '巴塞罗那' => { country: '西班牙', is_domestic: false },
  '阿姆斯特丹' => { country: '荷兰', is_domestic: false },
  '布拉格' => { country: '捷克', is_domestic: false },
  
  # 美洲
  '纽约' => { country: '美国', is_domestic: false },
  '洛杉矶' => { country: '美国', is_domestic: false },
  '旧金山' => { country: '美国', is_domestic: false },
  '拉斯维加斯' => { country: '美国', is_domestic: false },
  '多伦多' => { country: '加拿大', is_domestic: false },
  '温哥华' => { country: '加拿大', is_domestic: false },
  
  # 大洋洲
  '悉尼' => { country: '澳大利亚', is_domestic: false },
  '墨尔本' => { country: '澳大利亚', is_domestic: false },
  '黄金海岸' => { country: '澳大利亚', is_domestic: false },
  '奥克兰' => { country: '新西兰', is_domestic: false },
  '凯恩斯' => { country: '澳大利亚', is_domestic: false },
  '布里斯班' => { country: '澳大利亚', is_domestic: false },
  
  # 中东非洲
  '迪拜' => { country: '阿联酋', is_domestic: false },
  '阿布扎比' => { country: '阿联酋', is_domestic: false },
  '开罗' => { country: '埃及', is_domestic: false },
  '伊斯坦布尔' => { country: '土耳其', is_domestic: false },
  '特拉维夫' => { country: '以色列', is_domestic: false },
  '约翰内斯堡' => { country: '南非', is_domestic: false }
}

# Hotel types
hotel_types = ['hotel', 'homestay']

# Hotel brands (international brands)
international_brands = [
  '希尔顿', '万豪', '洲际', '香格里拉', '凯悦', '喜来登',
  '威斯汀', '丽思卡尔顿', '四季', '半岛', '文华东方',
  '悦榕庄', '安缦', 'Airbnb', '民宿', '精品酒店'
]

# Regions/districts by city
regions_by_city = {
  '曼谷' => ['素坤逸', '暹罗', '是隆', '考山路', '胜利纪念碑'],
  '普吉岛' => ['芭东海滩', '卡塔海滩', '卡伦海滩', '邦涛', '普吉镇'],
  '新加坡' => ['乌节路', '滨海湾', '克拉码头', '牛车水', '小印度'],
  '清迈' => ['古城', '尼曼路', '夜市区', '塔佩门', '清迈大学'],
  '亚庇' => ['市中心', '丹绒亚路', '加雅街', '水上清真寺', '机场'],
  '芭堤雅' => ['海滩路', '中天海滩', '南芭堤雅', '北芭堤雅', '纳克鲁瓦'],
  '吉隆坡' => ['双峰塔', '武吉免登', '唐人街', '独立广场', '中央车站'],
  '济州岛' => ['济州市', '西归浦', '中文观光区', '涯月', '城山'],
  '苏梅岛' => ['查汶海滩', '拉迈海滩', '波普海滩', '湄南海滩', '大佛海滩'],
  '甲米' => ['奥南海滩', '甲米镇', '兰塔岛', '皮皮岛码头', '莱利海滩'],
  
  '首尔' => ['明洞', '江南', '弘大', '东大门', '梨泰院'],
  '东京' => ['新宿', '涩谷', '银座', '浅草', '上野'],
  '大阪' => ['心斋桥', '梅田', '难波', '天王寺', '新大阪'],
  
  '伦敦' => ['威斯敏斯特', '伦敦塔桥', '肯辛顿', '苏活区', '金融城'],
  '巴黎' => ['香榭丽舍', '蒙马特', '卢浮宫', '埃菲尔铁塔', '拉丁区'],
  '罗马' => ['斗兽场', '特莱维喷泉', '西班牙广场', '梵蒂冈', '台伯河'],
  '巴塞罗那' => ['哥特区', '圣家堂', '兰布拉大街', '格拉西亚', '海滨'],
  '阿姆斯特丹' => ['中央火车站', '博物馆广场', '红灯区', '约旦区', '运河带'],
  '布拉格' => ['老城广场', '布拉格城堡', '查理大桥', '新城区', '小城区'],
  
  '纽约' => ['曼哈顿', '时代广场', '中央公园', '布鲁克林', '皇后区'],
  '洛杉矶' => ['好莱坞', '比佛利山', '圣莫尼卡', '市中心', '威尼斯海滩'],
  '旧金山' => ['联合广场', '渔人码头', '金融区', '唐人街', '硅谷'],
  '拉斯维加斯' => ['拉斯维加斯大道', '老城区', '市中心', '南拉斯维加斯', '北拉斯维加斯'],
  '多伦多' => ['市中心', 'CN塔', '皇后街', '约克维尔', '金融区'],
  '温哥华' => ['市中心', '煤气镇', '斯坦利公园', '格兰维尔岛', '北温哥华'],
  
  '悉尼' => ['悉尼歌剧院', '岩石区', '达令港', '邦迪海滩', '市中心'],
  '墨尔本' => ['市中心', '南岸', '圣基尔达', '菲茨罗伊', '唐人街'],
  '黄金海岸' => ['冲浪者天堂', '布罗德海滩', '库兰加塔', '梅因海滩', '南港'],
  '奥克兰' => ['市中心', '海港大桥', '天空塔', '使命湾', '帕内尔'],
  '凯恩斯' => ['市中心', '滨海大道', '棕榈湾', '三圣湾', '北部海滩'],
  '布里斯班' => ['市中心', '南岸', '福蒂图德谷', '袋鼠角', '新农场'],
  
  '迪拜' => ['市中心', '朱美拉海滩', '迪拜码头', '老城区', '棕榈岛'],
  '阿布扎比' => ['市中心', '亚斯岛', '萨迪亚特岛', '科尼切', '阿尔马丽娜'],
  '开罗' => ['吉萨金字塔', '开罗市中心', '扎马雷克', '伊斯兰开罗', '科普特开罗'],
  '伊斯坦布尔' => ['苏丹艾哈迈德', '塔克西姆', '贝伊奥卢', '博斯普鲁斯海峡', '加拉塔'],
  '特拉维夫' => ['海滨区', '雅法老城', '市中心', '白城', '弗洛伦廷'],
  '约翰内斯堡' => ['桑顿', '罗斯班克', '曼德拉广场', '金礁城', '索韦托']
}

international_cities.each do |city_name, city_data|
  regions = regions_by_city[city_name] || ['市中心', '商业区', '海滨区', '老城区', '新城区']
  
  # Create 8-12 hotels per city
  hotels_count = rand(8..12)
  
  hotels_count.times do |i|
    brand = international_brands.sample
    region = regions.sample
    hotel_type = hotel_types.sample
    star_level = rand(3..5)
    
    # Price ranges by star level (international hotels more expensive)
    price = case star_level
            when 5 then rand(800..2500)
            when 4 then rand(500..1200)
            else rand(300..800)
            end
    
    hotel = Hotel.create!(
      name: "#{city_name}#{brand}#{hotel_type == 'homestay' ? '民宿' : '酒店'}",
      city: city_name,
      address: "#{city_data[:country]}#{city_name}#{region}#{rand(1..999)}号",
      price: price,
      rating: rand(40..50) / 10.0,
      star_level: star_level,
      hotel_type: hotel_type,
      region: region,
      is_featured: i < 2, # First 2 are featured
      is_domestic: false,
      brand: brand,
      display_order: i
    )
    
    # Set image_url
    hotel_images = [
      "https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80&fm=jpg&fit=crop&auto=format",
      "https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=800&q=80&fm=jpg&fit=crop&auto=format",
      "https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=800&q=80&fm=jpg&fit=crop&auto=format",
      "https://images.unsplash.com/photo-1571003123894-1f0594d2b5d9?w=800&q=80&fm=jpg&fit=crop&auto=format",
      "https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=800&q=80&fm=jpg&fit=crop&auto=format"
    ]
    hotel.update(image_url: hotel_images.sample)
    
    # Create 3-5 rooms per hotel
    room_count = rand(3..5)
    room_count.times do |j|
      room_types = ['标准间', '豪华间', '套房', '家庭房', '海景房']
      room_type = room_types.sample
      
      HotelRoom.create!(
        hotel: hotel,
        room_type: room_type,
        price: hotel.price + rand(-100..300),
        available_rooms: rand(5..20),
        room_category: 'overnight'
      )
    end
    
    # Create hotel policy
    HotelPolicy.create!(
      hotel: hotel,
      check_in_time: "15:00后",
      check_out_time: "12:00前",
      pet_policy: "部分房型可携带宠物，需提前联系酒店",
      breakfast_type: star_level >= 4 ? "自助餐" : "其他",
      breakfast_hours: "每天07:00-10:00",
      breakfast_price: star_level >= 4 ? rand(80..150) : rand(40..80),
      payment_methods: ["信用卡", "现金", "支付宝"]
    )
    
    # Create 2-4 facilities
    facilities_data = [
      { name: '免费WiFi', icon: 'wifi', description: '全酒店覆盖高速无线网络', category: '网络' },
      { name: '停车场', icon: 'parking', description: '免费地下停车位', category: '停车' },
      { name: '游泳池', icon: 'swimmer', description: '室内恒温游泳池', category: '娱乐' },
      { name: '健身房', icon: 'dumbbell', description: '24小时开放的现代化健身中心', category: '健身' },
      { name: '餐厅', icon: 'utensils', description: '提供中西式美食', category: '餐饮' },
      { name: '会议室', icon: 'briefcase', description: '提供办公和会议设施', category: '商务' },
      { name: '机场接送', icon: 'car', description: '提供机场接送服务', category: '服务' },
      { name: '洗衣服务', icon: 'tshirt', description: '提供洗衣熨烫服务', category: '服务' }
    ]
    rand(2..4).times do
      facility = facilities_data.sample
      HotelFacility.create!(
        hotel: hotel,
        name: facility[:name],
        icon: facility[:icon],
        description: facility[:description],
        category: facility[:category]
      )
    end
    
    # Create 2-3 reviews (need a user)
    user = User.first || User.create!(
      email: "demo@example.com",
      password_digest: BCrypt::Password.create("password123")
    )
    
    rand(2..3).times do
      HotelReview.create!(
        hotel: hotel,
        user: user,
        rating: rand(40..50) / 10.0,
        comment: "酒店位置优越，服务周到，房间舒适干净。#{city_name}的好选择！"
      )
    end
  end
  
  puts "Created #{hotels_count} hotels for #{city_name} (#{city_data[:country]})"
end

puts "International hotels created successfully!"
puts "Total international hotels: #{Hotel.international.count}"
