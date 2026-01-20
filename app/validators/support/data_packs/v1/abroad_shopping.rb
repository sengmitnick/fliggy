# Abroad Shopping Seeds
# 境外购物数据包 - 使用批量插入优化

puts "Creating Abroad Brands and Shops..."

timestamp = Time.current

# 1. 清理现有数据
AbroadCoupon.delete_all
AbroadShop.delete_all
AbroadBrand.delete_all

# 2. 批量插入品牌
brands_data = [
  {
    name: "爱电王",
    country: "日本",
    category: "duty_free",
    description: "EDION是日本知名的电器连锁店，提供高达7%的立减优惠和免税服务。",
    logo_url: "https://images.unsplash.com/photo-1550009158-9ebf69173e03?w=200&h=200&fit=crop",
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "ANA 【全日空免税店】",
    country: "日本",
    category: "duty_free",
    description: "【ANA DUTY FREE SHOP 全日空免税】位于成田机场第 1 航站楼南翼出国出境审查区商店。除了 THE GINZA、Clé de Peau Beauté 、SUQQU 等广受欢迎的日本化妆品外，还有许多国际品牌，如 YSL等。此外，还有在海外越来越受欢迎的日本清酒和日本威士忌，以及中国的高级白酒茅台酒等，酒类种类丰富。",
    logo_url: "https://images.unsplash.com/photo-1436491865332-7a61a109cc05?w=200&h=200&fit=crop",
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "近铁百货",
    country: "日本",
    category: "department_store",
    description: "近铁百货，源自日本的零售巨擘，诞生于铁路发展的繁荣之中，与近铁集团紧密相连。自创立以来，它不仅是一个购物中心，更是日本现代零售文化的象征。",
    logo_url: "https://images.unsplash.com/photo-1555529669-e69e7aa0ba9a?w=200&h=200&fit=crop",
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "大丸松坂屋百货",
    country: "日本",
    category: "department_store",
    description: "大丸松坂屋百货是日本历史悠久的高端百货商店，提供减5%优惠和餐饮代金券。",
    logo_url: "https://images.unsplash.com/photo-1555529669-e69e7aa0ba9a?w=200&h=200&fit=crop",
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "Bic Camera",
    country: "日本",
    category: "duty_free",
    description: "Bic Camera是日本知名的电器连锁店，提供95折优惠。",
    logo_url: "https://images.unsplash.com/photo-1550009158-9ebf69173e03?w=200&h=200&fit=crop",
    featured: false,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "科摩思COSMOS",
    country: "日本",
    category: "cosmeceuticals",
    description: "科摩思药妆是日本知名的药妆连锁店，提供满额立减7%和免税服务。",
    logo_url: "https://images.unsplash.com/photo-1596755389378-c31d21fd1273?w=200&h=200&fit=crop",
    featured: false,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "AKAKABE PHARMACY 【赤壁药妆】",
    country: "日本",
    category: "cosmeceuticals",
    description: "赤壁药妆是日本知名的药妆连锁店，提供92折+免税服务。",
    logo_url: "https://images.unsplash.com/photo-1596755389378-c31d21fd1273?w=200&h=200&fit=crop",
    featured: false,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "京王新宿店",
    country: "日本",
    category: "department_store",
    description: "京王百货新宿店提供95折和10%免税优惠。",
    logo_url: "https://images.unsplash.com/photo-1555529669-e69e7aa0ba9a?w=200&h=200&fit=crop",
    featured: false,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "小田急百货店（新宿店）",
    country: "日本",
    category: "department_store",
    description: "小田急百货新宿店提供94折和10%免税优惠。",
    logo_url: "https://images.unsplash.com/photo-1555529669-e69e7aa0ba9a?w=200&h=200&fit=crop",
    featured: false,
    created_at: timestamp,
    updated_at: timestamp
  }
]

AbroadBrand.insert_all(brands_data)
puts "✓ 批量创建了 #{brands_data.count} 个品牌"

# 重新加载以获取ID映射
brands_map = AbroadBrand.pluck(:name, :id).to_h

# 3. 批量插入门店
shops_data = [
  # ANA 全日空免税店
  {
    name: "【全日空免税 南翼店】",
    abroad_brand_id: brands_map["ANA 【全日空免税店】"],
    city: "成田市",
    address: "千叶县成田市成田国际机场 第1航站楼南翼出国出境审查区",
    description: "位于成田机场第 1 航站楼南翼出出国境审查区出口后的左手边的第二家商店。",
    image_url: "https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=400&h=300&fit=crop",
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "【全日空免税 第4卫星厅店】",
    abroad_brand_id: brands_map["ANA 【全日空免税店】"],
    city: "成田市",
    address: "千叶县成田市成田国际机场 第1航站楼第4卫星厅",
    description: "位于成田机场第 1 航站楼第4卫星厅的免税店。",
    image_url: "https://images.unsplash.com/photo-1555529669-e69e7aa0ba9a?w=400&h=300&fit=crop",
    created_at: timestamp,
    updated_at: timestamp
  },
  # 科摩思COSMOS
  {
    name: "科摩思-道顿堀店",
    abroad_brand_id: brands_map["科摩思COSMOS"],
    city: "大阪",
    address: "大阪市中央区道顿堀",
    description: "位于大阪道顿堀商圈的药妆店。",
    image_url: "https://images.unsplash.com/photo-1590559899731-a363ad00a649?w=400&h=300&fit=crop",
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "科摩思-歌舞伎町一丁目店",
    abroad_brand_id: brands_map["科摩思COSMOS"],
    city: "东京",
    address: "东京都新宿区歌舞伎町一丁目",
    description: "位于东京新宿歌舞伎町的药妆店。",
    image_url: "https://images.unsplash.com/photo-1578469645742-46cae010e5d4?w=400&h=300&fit=crop",
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "科摩思-心斋桥南店",
    abroad_brand_id: brands_map["科摩思COSMOS"],
    city: "大阪",
    address: "大阪市中央区心斋桥",
    description: "位于大阪心斋桥商圈的药妆店。",
    image_url: "https://images.unsplash.com/photo-1623861214041-39655848e109?w=400&h=300&fit=crop",
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "科摩思-天神大丸店",
    abroad_brand_id: brands_map["科摩思COSMOS"],
    city: "福岡",
    address: "福冈县福冈市中央区天神",
    description: "位于福冈天神大丸百货的药妆店。",
    image_url: "https://images.unsplash.com/photo-1533050487297-09b450131914?w=400&h=300&fit=crop",
    created_at: timestamp,
    updated_at: timestamp
  },
  # 赤壁药妆
  {
    name: "AKAKABE PHARMACY 【赤壁药妆】",
    abroad_brand_id: brands_map["AKAKABE PHARMACY 【赤壁药妆】"],
    city: "大阪市",
    address: "大阪市中央区",
    description: "位于大阪市中心的药妆店。",
    image_url: "https://images.unsplash.com/photo-1596755389378-c31d21fd1273?w=400&h=300&fit=crop",
    created_at: timestamp,
    updated_at: timestamp
  },
  # 京王新宿店
  {
    name: "京王新宿店",
    abroad_brand_id: brands_map["京王新宿店"],
    city: "东京",
    address: "东京都新宿区西新宿",
    description: "位于新宿的京王百货店。",
    image_url: "https://images.unsplash.com/photo-1555529669-e69e7aa0ba9a?w=400&h=300&fit=crop",
    created_at: timestamp,
    updated_at: timestamp
  },
  # 小田急百货店
  {
    name: "小田急百货店（新宿店）",
    abroad_brand_id: brands_map["小田急百货店（新宿店）"],
    city: "东京",
    address: "东京都新宿区西新宿",
    description: "位于新宿的小田急百货店。",
    image_url: "https://images.unsplash.com/photo-1555529669-e69e7aa0ba9a?w=400&h=300&fit=crop",
    created_at: timestamp,
    updated_at: timestamp
  }
]

AbroadShop.insert_all(shops_data)
puts "✓ 批量创建了 #{shops_data.count} 个门店"

# 重新加载以获取ID映射
shops_map = AbroadShop.pluck(:name, :id).to_h

# 4. 批量插入优惠券
coupons_data = []

# ANA 全日空免税店优惠券
["【全日空免税 南翼店】", "【全日空免税 第4卫星厅店】"].each do |shop_name|
  coupons_data << {
    title: "购物金额的 5% 折扣",
    abroad_brand_id: brands_map["ANA 【全日空免税店】"],
    abroad_shop_id: shops_map[shop_name],
    discount_type: "percentage",
    discount_value: "5",
    description: "1家ANA 【全日空免税店】 门店可用",
    valid_from: Date.today,
    valid_until: Date.today + 2.years,
    active: true,
    created_at: timestamp,
    updated_at: timestamp
  }
end

# 科摩思COSMOS优惠券
["科摩思-道顿堀店", "科摩思-歌舞伎町一丁目店", "科摩思-心斋桥南店", "科摩思-天神大丸店"].each do |shop_name|
  # 满额立减7%
  coupons_data << {
    title: "满额立减7%",
    abroad_brand_id: brands_map["科摩思COSMOS"],
    abroad_shop_id: shops_map[shop_name],
    discount_type: "percentage",
    discount_value: "7",
    description: "满额立减7%",
    valid_from: Date.today,
    valid_until: Date.today + 1.year,
    active: true,
    created_at: timestamp,
    updated_at: timestamp
  }
  # 免税
  coupons_data << {
    title: "免税",
    abroad_brand_id: brands_map["科摩思COSMOS"],
    abroad_shop_id: shops_map[shop_name],
    discount_type: "tax_free",
    discount_value: "免税",
    description: "免税",
    valid_from: Date.today,
    valid_until: Date.today + 1.year,
    active: true,
    created_at: timestamp,
    updated_at: timestamp
  }
end

# 赤壁药妆优惠券
coupons_data << {
  title: "可享92折+免税",
  abroad_brand_id: brands_map["AKAKABE PHARMACY 【赤壁药妆】"],
  abroad_shop_id: shops_map["AKAKABE PHARMACY 【赤壁药妆】"],
  discount_type: "percentage",
  discount_value: "92",
  description: "可享92折+免税",
  valid_from: Date.today,
  valid_until: Date.today + 1.year,
  active: true,
  created_at: timestamp,
  updated_at: timestamp
}

# 京王新宿店优惠券
coupons_data << {
  title: "立享95折 + 10%免税",
  abroad_brand_id: brands_map["京王新宿店"],
  abroad_shop_id: shops_map["京王新宿店"],
  discount_type: "percentage",
  discount_value: "95",
  description: "立享95折 + 10%免税",
  valid_from: Date.today,
  valid_until: Date.today + 1.year,
  active: true,
  created_at: timestamp,
  updated_at: timestamp
}

# 小田急百货店优惠券
coupons_data << {
  title: "立享94折+10%免税",
  abroad_brand_id: brands_map["小田急百货店（新宿店）"],
  abroad_shop_id: shops_map["小田急百货店（新宿店）"],
  discount_type: "percentage",
  discount_value: "94",
  description: "立享94折+10%免税",
  valid_from: Date.today,
  valid_until: Date.today + 1.year,
  active: true,
  created_at: timestamp,
  updated_at: timestamp
}

AbroadCoupon.insert_all(coupons_data)

puts "✓ 批量创建了 #{coupons_data.count} 张优惠券"
puts "\n✅ 境外购物数据加载完成！"
puts "  - 品牌总数: #{AbroadBrand.count}"
puts "  - 门店总数: #{AbroadShop.count}"
puts "  - 优惠券总数: #{AbroadCoupon.count}"
