# 酒店种子数据 - 覆盖所有快捷标签
puts "正在创建深圳酒店数据..."

# 清空现有酒店数据
Hotel.destroy_all

# 亲子出游相关酒店
family_hotels = [
  {
    name: "深圳欢乐亲子度假酒店",
    city: "深圳市",
    address: "南山区欢乐海岸亲子游乐园旁",
    rating: 4.8,
    price: 688,
    original_price: 988,
    distance: "距宝安机场25公里",
    star_level: 5,
    hotel_type: "hotel",
    is_featured: true,
    features: ["亲子套房", "儿童乐园", "亲子餐厅", "室内游泳池"].to_json,
    image_url: "https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800"
  },
  {
    name: "深圳童趣主题酒店",
    city: "深圳市",
    address: "福田区亲子教育基地旁",
    rating: 4.7,
    price: 588,
    original_price: 788,
    distance: "距福田站2公里",
    star_level: 4,
    hotel_type: "hotel",
    is_featured: false,
    features: ["亲子房", "儿童游乐设施", "早餐含儿童餐", "亲子活动"].to_json,
    image_url: "https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=800"
  },
  {
    name: "深圳海洋主题亲子民宿",
    city: "深圳市",
    address: "南山区欢乐港湾海洋主题公园旁",
    rating: 4.9,
    price: 498,
    original_price: 698,
    distance: "距欢乐港湾500米",
    star_level: 4,
    hotel_type: "homestay",
    is_featured: true,
    features: ["海洋主题房", "亲子互动区", "儿童早餐", "益智玩具"].to_json,
    image_url: "https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800"
  },
  {
    name: "深圳亲子乐园酒店",
    city: "深圳市",
    address: "罗湖区东门商圈亲子游乐中心",
    rating: 4.6,
    price: 458,
    original_price: 658,
    distance: "距罗湖口岸3公里",
    star_level: 4,
    hotel_type: "hotel",
    is_featured: false,
    features: ["亲子套房", "室内游乐场", "儿童托管", "家庭聚餐"].to_json,
    image_url: "https://images.unsplash.com/photo-1564501049412-61c2a3083791?w=800"
  }
]

family_hotels.each do |hotel_data|
  hotel = Hotel.create!(hotel_data)
  puts "  ✓ 创建亲子出游酒店: #{hotel.name}"
end

# 福田站附近酒店
futian_hotels = [
  {
    name: "深圳福田站商务酒店",
    city: "深圳市",
    address: "福田区福田站南广场100米",
    rating: 4.7,
    price: 388,
    original_price: 588,
    distance: "距福田站100米",
    star_level: 4,
    hotel_type: "hotel",
    is_featured: true,
    features: ["高铁直达", "商务中心", "会议室", "免费接站"].to_json,
    image_url: "https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=800"
  },
  {
    name: "福田站快捷酒店",
    city: "深圳市",
    address: "福田区福田站东侧200米",
    rating: 4.5,
    price: 268,
    original_price: 368,
    distance: "距福田站200米",
    star_level: 3,
    hotel_type: "hotel",
    is_featured: false,
    features: ["地铁直达", "24小时前台", "快速入住", "行李寄存"].to_json,
    image_url: "https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=800"
  },
  {
    name: "福田站豪华公寓",
    city: "深圳市",
    address: "福田区福田站西广场步行3分钟",
    rating: 4.8,
    price: 568,
    original_price: 768,
    distance: "距福田站300米",
    star_level: 5,
    hotel_type: "homestay",
    is_featured: true,
    features: ["高铁站旁", "全景落地窗", "智能家居", "免费停车"].to_json,
    image_url: "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800"
  },
  {
    name: "福田中心精品酒店",
    city: "深圳市",
    address: "福田区福田站北侧500米",
    rating: 4.6,
    price: 428,
    original_price: 528,
    distance: "距福田站500米",
    star_level: 4,
    hotel_type: "hotel",
    is_featured: false,
    features: ["步行可达福田站", "商圈中心", "健身房", "自助早餐"].to_json,
    image_url: "https://images.unsplash.com/photo-1590490360182-c33d57733427?w=800"
  },
  {
    name: "福田站温馨民宿",
    city: "深圳市",
    address: "福田区福田站附近居民区",
    rating: 4.4,
    price: 218,
    original_price: 318,
    distance: "距福田站800米",
    star_level: 3,
    hotel_type: "homestay",
    is_featured: false,
    features: ["近福田站", "温馨舒适", "厨房设施", "洗衣机"].to_json,
    image_url: "https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=800"
  }
]

futian_hotels.each do |hotel_data|
  hotel = Hotel.create!(hotel_data)
  puts "  ✓ 创建福田站酒店: #{hotel.name}"
end

# 宝安机场附近酒店
airport_hotels = [
  {
    name: "深圳宝安国际机场酒店",
    city: "深圳市",
    address: "宝安区宝安机场T3航站楼内",
    rating: 4.9,
    price: 788,
    original_price: 1088,
    distance: "距宝安机场0米",
    star_level: 5,
    hotel_type: "hotel",
    is_featured: true,
    features: ["机场内", "24小时入住", "航班信息", "免费接送"].to_json,
    image_url: "https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=800"
  },
  {
    name: "宝安机场快捷酒店",
    city: "深圳市",
    address: "宝安区机场大道宝安机场500米",
    rating: 4.6,
    price: 328,
    original_price: 428,
    distance: "距宝安机场500米",
    star_level: 3,
    hotel_type: "hotel",
    is_featured: false,
    features: ["近机场", "免费班车", "24小时前台", "早餐打包"].to_json,
    image_url: "https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=800"
  },
  {
    name: "宝安机场商务酒店",
    city: "深圳市",
    address: "宝安区机场东路宝安机场旁",
    rating: 4.7,
    price: 488,
    original_price: 688,
    distance: "距宝安机场1公里",
    star_level: 4,
    hotel_type: "hotel",
    is_featured: true,
    features: ["机场附近", "商务设施", "会议室", "免费接送机"].to_json,
    image_url: "https://images.unsplash.com/photo-1566195992011-5f6b21e539aa?w=800"
  },
  {
    name: "机场周边精选民宿",
    city: "深圳市",
    address: "宝安区福永街道宝安机场2公里",
    rating: 4.5,
    price: 258,
    original_price: 358,
    distance: "距宝安机场2公里",
    star_level: 3,
    hotel_type: "homestay",
    is_featured: false,
    features: ["机场周边", "免费停车", "厨房设施", "安静舒适"].to_json,
    image_url: "https://images.unsplash.com/photo-1595576508898-0ad5c879a061?w=800"
  },
  {
    name: "宝安机场豪华套房",
    city: "深圳市",
    address: "宝安区航城街道近宝安机场",
    rating: 4.8,
    price: 688,
    original_price: 888,
    distance: "距宝安机场1.5公里",
    star_level: 5,
    hotel_type: "hotel",
    is_featured: true,
    features: ["近宝安机场", "豪华装修", "免费接送", "健身中心"].to_json,
    image_url: "https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=800"
  }
]

airport_hotels.each do |hotel_data|
  hotel = Hotel.create!(hotel_data)
  puts "  ✓ 创建宝安机场酒店: #{hotel.name}"
end

# 欢乐港湾附近酒店
harbor_hotels = [
  {
    name: "深圳欢乐港湾海景酒店",
    city: "深圳市",
    address: "南山区欢乐港湾滨海大道",
    rating: 4.9,
    price: 888,
    original_price: 1288,
    distance: "距欢乐港湾100米",
    star_level: 5,
    hotel_type: "hotel",
    is_featured: true,
    features: ["海景房", "欢乐港湾旁", "摩天轮景观", "无边泳池"].to_json,
    image_url: "https://images.unsplash.com/photo-1571003123894-1f0594d2b5d9?w=800"
  },
  {
    name: "欢乐港湾度假公寓",
    city: "深圳市",
    address: "南山区欢乐港湾商业街",
    rating: 4.7,
    price: 588,
    original_price: 788,
    distance: "距欢乐港湾200米",
    star_level: 4,
    hotel_type: "homestay",
    is_featured: true,
    features: ["欢乐港湾内", "海滨景观", "购物方便", "餐饮丰富"].to_json,
    image_url: "https://images.unsplash.com/photo-1502672260066-6bc35f0a97eb?w=800"
  },
  {
    name: "南山欢乐港湾精品民宿",
    city: "深圳市",
    address: "南山区欢乐港湾附近社区",
    rating: 4.6,
    price: 428,
    original_price: 628,
    distance: "距欢乐港湾500米",
    star_level: 4,
    hotel_type: "homestay",
    is_featured: false,
    features: ["近欢乐港湾", "温馨装修", "厨房设备", "海景阳台"].to_json,
    image_url: "https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=800"
  },
  {
    name: "欢乐港湾商务酒店",
    city: "深圳市",
    address: "南山区欢乐港湾周边商圈",
    rating: 4.5,
    price: 388,
    original_price: 488,
    distance: "距欢乐港湾800米",
    star_level: 3,
    hotel_type: "hotel",
    is_featured: false,
    features: ["欢乐港湾附近", "商务设施", "会议室", "停车场"].to_json,
    image_url: "https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=800"
  }
]

harbor_hotels.each do |hotel_data|
  hotel = Hotel.create!(hotel_data)
  puts "  ✓ 创建欢乐港湾酒店: #{hotel.name}"
end

# 罗湖口岸附近酒店
luohu_hotels = [
  {
    name: "深圳罗湖口岸商务酒店",
    city: "深圳市",
    address: "罗湖区罗湖口岸广场50米",
    rating: 4.7,
    price: 368,
    original_price: 568,
    distance: "距罗湖口岸50米",
    star_level: 4,
    hotel_type: "hotel",
    is_featured: true,
    features: ["口岸旁", "通关便利", "24小时服务", "行李寄存"].to_json,
    image_url: "https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=800"
  },
  {
    name: "罗湖口岸快捷酒店",
    city: "深圳市",
    address: "罗湖区罗湖口岸东侧200米",
    rating: 4.5,
    price: 258,
    original_price: 358,
    distance: "距罗湖口岸200米",
    star_level: 3,
    hotel_type: "hotel",
    is_featured: false,
    features: ["近罗湖口岸", "地铁直达", "快速入住", "免费WiFi"].to_json,
    image_url: "https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=800"
  },
  {
    name: "罗湖口岸豪华酒店",
    city: "深圳市",
    address: "罗湖区罗湖口岸商业中心",
    rating: 4.8,
    price: 588,
    original_price: 788,
    distance: "距罗湖口岸100米",
    star_level: 5,
    hotel_type: "hotel",
    is_featured: true,
    features: ["罗湖口岸旁", "豪华装修", "行政酒廊", "通关指引"].to_json,
    image_url: "https://images.unsplash.com/photo-1566665797739-1674de7a421a?w=800"
  },
  {
    name: "罗湖口岸温馨民宿",
    city: "深圳市",
    address: "罗湖区罗湖口岸附近居民区",
    rating: 4.4,
    price: 198,
    original_price: 298,
    distance: "距罗湖口岸500米",
    star_level: 3,
    hotel_type: "homestay",
    is_featured: false,
    features: ["口岸附近", "性价比高", "厨房设施", "安静舒适"].to_json,
    image_url: "https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=800"
  },
  {
    name: "罗湖口岸精品公寓",
    city: "深圳市",
    address: "罗湖区罗湖口岸西侧300米",
    rating: 4.6,
    price: 428,
    original_price: 528,
    distance: "距罗湖口岸300米",
    star_level: 4,
    hotel_type: "homestay",
    is_featured: false,
    features: ["近罗湖口岸", "全新装修", "智能家居", "洗衣机"].to_json,
    image_url: "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800"
  }
]

luohu_hotels.each do |hotel_data|
  hotel = Hotel.create!(hotel_data)
  puts "  ✓ 创建罗湖口岸酒店: #{hotel.name}"
end

# 综合型酒店（覆盖多个标签）
multi_tag_hotels = [
  {
    name: "深圳湾超级假日酒店",
    city: "深圳市",
    address: "南山区深圳湾畔欢乐港湾商圈",
    rating: 4.9,
    price: 988,
    original_price: 1388,
    distance: "距欢乐港湾300米",
    star_level: 5,
    hotel_type: "hotel",
    is_featured: true,
    features: ["亲子套房", "海景房", "近欢乐港湾", "儿童乐园", "无边泳池"].to_json,
    image_url: "https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=800"
  },
  {
    name: "深圳中心枢纽酒店",
    city: "深圳市",
    address: "福田区福田站商圈中心",
    rating: 4.8,
    price: 688,
    original_price: 888,
    distance: "距福田站300米，距罗湖口岸5公里",
    star_level: 5,
    hotel_type: "hotel",
    is_featured: true,
    features: ["近福田站", "商务中心", "亲子房", "会议室", "免费接站"].to_json,
    image_url: "https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=800"
  },
  {
    name: "深圳全能家庭公寓",
    city: "深圳市",
    address: "福田区车公庙亲子活动中心旁",
    rating: 4.7,
    price: 558,
    original_price: 758,
    distance: "距福田站1.5公里，距宝安机场20公里",
    star_level: 4,
    hotel_type: "homestay",
    is_featured: true,
    features: ["亲子设施", "近福田站", "厨房设备", "儿童玩具", "免费停车"].to_json,
    image_url: "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800"
  }
]

multi_tag_hotels.each do |hotel_data|
  hotel = Hotel.create!(hotel_data)
  puts "  ✓ 创建综合型酒店: #{hotel.name}"
end

puts "✅ 深圳酒店数据创建完成！共创建 #{Hotel.count} 家酒店"
puts "  - 亲子出游: #{Hotel.where("name LIKE ? OR address LIKE ? OR features LIKE ?", "%亲子%", "%亲子%", "%亲子%").count} 家"
puts "  - 福田站: #{Hotel.where("name LIKE ? OR address LIKE ?", "%福田站%", "%福田站%").count} 家"
puts "  - 宝安机场: #{Hotel.where("name LIKE ? OR address LIKE ?", "%宝安机场%", "%宝安机场%").count} 家"
puts "  - 欢乐港湾: #{Hotel.where("name LIKE ? OR address LIKE ?", "%欢乐港湾%", "%欢乐港湾%").count} 家"
puts "  - 罗湖口岸: #{Hotel.where("name LIKE ? OR address LIKE ?", "%罗湖口岸%", "%罗湖口岸%").count} 家"
