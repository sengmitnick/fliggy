# Hotel Packages Seed Data


brands = [
  { name: "华住", logo: "https://images.unsplash.com/photo-1566073771259-6a8506099945?w=400&q=80&fm=jpg&fit=crop&auto=format" },
  { name: "万豪", logo: "https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=400&q=80&fm=jpg&fit=crop&auto=format" },
  { name: "希尔顿", logo: "https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=400&q=80&fm=jpg&fit=crop&auto=format" },
  { name: "洲际", logo: "https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=400&q=80&fm=jpg&fit=crop&auto=format" },
  { name: "凯悦", logo: "https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=400&q=80&fm=jpg&fit=crop&auto=format" },
  { name: "香格里拉", logo: "https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=400&q=80&fm=jpg&fit=crop&auto=format" }
]

regions = ["全国通用", "华东地区", "华南地区", "华北地区", "西南地区", "华中地区"]

packages_data = [
  { 
    title: "【官方直营】华住美仑品牌全国140+店2晚可折分通兑 全程不加价", 
    description: "含早餐，可叠加会员权益，全国140+门店通用",
    price: 699,
    original_price: 999,
    package_type: "vip",
    city: "武汉",
    night_count: 2,
    refundable: false,
    instant_booking: true,
    luxury: false
  },
  { 
    title: "万豪酒店2晚通兑套餐 高端商务之选", 
    description: "包含双早，行政酒廊权益，全国万豪旗下酒店通用",
    price: 1299,
    original_price: 1799,
    package_type: "vip",
    city: "武汉",
    night_count: 2,
    refundable: true,
    instant_booking: true,
    luxury: true
  },
  { 
    title: "希尔顿酒店套餐 家庭亲子首选", 
    description: "含双早+双晚餐，儿童免费，全国希尔顿品牌通用",
    price: 1099,
    original_price: 1499,
    package_type: "standard",
    city: "武汉",
    night_count: 2,
    refundable: true,
    instant_booking: false,
    luxury: false
  },
  { 
    title: "洲际酒店奢华体验套餐", 
    description: "豪华房型升级，SPA体验，米其林餐厅体验",
    price: 1899,
    original_price: 2599,
    package_type: "vip",
    city: "上海",
    night_count: 2,
    refundable: false,
    instant_booking: true,
    luxury: true
  },
  { 
    title: "凯悦酒店度假套餐 限时特惠", 
    description: "含三餐自助，免费延迟退房，景区门票折扣",
    price: 1499,
    original_price: 1999,
    package_type: "limited",
    city: "北京",
    night_count: 2,
    refundable: true,
    instant_booking: true,
    luxury: false
  },
  { 
    title: "香格里拉酒店尊享套餐", 
    description: "行政套房，管家服务，机场接送，专属礼遇",
    price: 2299,
    original_price: 3299,
    package_type: "vip",
    city: "深圳",
    night_count: 2,
    refundable: false,
    instant_booking: false,
    luxury: true
  },
  { 
    title: "华住精选商旅套餐 5晚通兑", 
    description: "全国门店通用，不限房型，周末不加价",
    price: 899,
    original_price: 1299,
    package_type: "standard",
    city: "杭州",
    night_count: 5,
    refundable: true,
    instant_booking: true,
    luxury: false
  },
  { 
    title: "万豪度假酒店3晚套餐", 
    description: "含早餐+下午茶，免费使用泳池健身房",
    price: 1699,
    original_price: 2199,
    package_type: "standard",
    city: "三亚",
    night_count: 3,
    refundable: true,
    instant_booking: true,
    luxury: false
  },
  { 
    title: "希尔顿商务精选 工作日专享", 
    description: "工作日专用，含早餐，免费会议室使用",
    price: 799,
    original_price: 1099,
    package_type: "limited",
    city: "广州",
    night_count: 2,
    refundable: false,
    instant_booking: true,
    luxury: false
  },
  { 
    title: "洲际周末度假套餐", 
    description: "周末专用，含双人早餐+欢迎水果",
    price: 1299,
    original_price: 1699,
    package_type: "standard",
    city: "成都",
    night_count: 2,
    refundable: true,
    instant_booking: false,
    luxury: false
  }
]

brands.each_with_index do |brand, brand_idx|
  # Create 2-3 packages per brand
  packages_per_brand = packages_data[brand_idx * 2, 2] || []
  
  packages_per_brand.each_with_index do |package_info, pkg_idx|
    package = HotelPackage.find_or_create_by!(
      brand_name: brand[:name],
      title: package_info[:title]
    ) do |p|
      p.description = package_info[:description]
      p.price = package_info[:price]
      p.original_price = package_info[:original_price]
      p.sales_count = rand(100..9999)
      p.is_featured = (brand_idx + pkg_idx).even?
      p.valid_days = 365
      p.terms = "1. 套餐有效期365天\n2. 可在品牌旗下任意门店使用\n3. 需提前3天预约\n4. 不可退款，可转让\n5. 节假日可能需要补差价"
      p.region = regions.sample
      p.package_type = package_info[:package_type]
      p.display_order = brand_idx * 10 + pkg_idx
      p.city = package_info[:city]
      p.night_count = package_info[:night_count]
      p.refundable = package_info[:refundable]
      p.instant_booking = package_info[:instant_booking]
      p.luxury = package_info[:luxury]
      p.brand_logo_url = brand[:logo]  # 直接设置图片URL字段
    end
    
    # 为每个套餐生成选项
    package.generate_options
    
    print "."
  end
end

puts "\n✅ Created #{HotelPackage.count} hotel packages"
puts "   - Featured: #{HotelPackage.featured.count}"
puts "   - VIP: #{HotelPackage.by_type('vip').count}"
puts "   - Standard: #{HotelPackage.by_type('standard').count}"
puts "   - Limited: #{HotelPackage.by_type('limited').count}"
puts "   - Package Options: #{PackageOption.count}"
