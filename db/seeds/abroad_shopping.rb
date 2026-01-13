# Abroad Shopping Seeds

puts "Creating Abroad Brands and Shops..."

# 1. 爱电王 (EDION) - 电器免税店
edion = AbroadBrand.find_or_create_by!(name: "爱电王") do |brand|
  brand.country = "日本"
  brand.category = "duty_free"
  brand.description = "EDION是日本知名的电器连锁店，提供高达7%的立减优惠和免税服务。"
  brand.logo_url = "https://images.unsplash.com/photo-1550009158-9ebf69173e03?w=200&h=200&fit=crop"
  brand.featured = true
end

# 2. 全日空免税 (ANA DUTY FREE)
ana = AbroadBrand.find_or_create_by!(name: "ANA 【全日空免税店】") do |brand|
  brand.country = "日本"
  brand.category = "duty_free"
  brand.description = "【ANA DUTY FREE SHOP 全日空免税】位于成田机场第 1 航站楼南翼出国出境审查区商店。除了 THE GINZA、Clé de Peau Beauté 、SUQQU 等广受欢迎的日本化妆品外，还有许多国际品牌，如 YSL等。此外，还有在海外越来越受欢迎的日本清酒和日本威士忌，以及中国的高级白酒茅台酒等，酒类种类丰富。"
  brand.logo_url = "https://images.unsplash.com/photo-1436491865332-7a61a109cc05?w=200&h=200&fit=crop"
  brand.featured = true
end

ana_south = AbroadShop.find_or_create_by!(name: "【全日空免税 南翼店】", abroad_brand: ana) do |shop|
  shop.city = "成田市"
  shop.address = "千叶县成田市成田国际机场 第1航站楼南翼出国出境审查区"
  shop.description = "位于成田机场第 1 航站楼南翼出出国境审查区出口后的左手边的第二家商店。"
  shop.image_url = "https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=400&h=300&fit=crop"
end

ana_satellite = AbroadShop.find_or_create_by!(name: "【全日空免税 第4卫星厅店】", abroad_brand: ana) do |shop|
  shop.city = "成田市"
  shop.address = "千叶县成田市成田国际机场 第1航站楼第4卫星厅"
  shop.description = "位于成田机场第 1 航站楼第4卫星厅的免税店。"
  shop.image_url = "https://images.unsplash.com/photo-1555529669-e69e7aa0ba9a?w=400&h=300&fit=crop"
end

AbroadCoupon.find_or_create_by!(title: "购物金额的 5% 折扣", abroad_brand: ana, abroad_shop: ana_south) do |coupon|
  coupon.discount_type = "percentage"
  coupon.discount_value = "5"
  coupon.description = "1家ANA 【全日空免税店】 门店可用"
  coupon.valid_from = Date.today
  coupon.valid_until = Date.today + 2.years
  coupon.active = true
end

AbroadCoupon.find_or_create_by!(title: "购物金额的 5% 折扣", abroad_brand: ana, abroad_shop: ana_satellite) do |coupon|
  coupon.discount_type = "percentage"
  coupon.discount_value = "5"
  coupon.description = "1家ANA 【全日空免税店】 门店可用"
  coupon.valid_from = Date.today
  coupon.valid_until = Date.today + 2.years
  coupon.active = true
end

# 3. 近铁百货店 (Kintetsu)
kintetsu = AbroadBrand.find_or_create_by!(name: "近铁百货") do |brand|
  brand.country = "日本"
  brand.category = "department_store"
  brand.description = "近铁百货，源自日本的零售巨擘，诞生于铁路发展的繁荣之中，与近铁集团紧密相连。自创立以来，它不仅是一个购物中心，更是日本现代零售文化的象征。"
  brand.logo_url = "https://images.unsplash.com/photo-1555529669-e69e7aa0ba9a?w=200&h=200&fit=crop"
  brand.featured = true
end

# 4. 大丸松坂屋百货
daimaru = AbroadBrand.find_or_create_by!(name: "大丸松坂屋百货") do |brand|
  brand.country = "日本"
  brand.category = "department_store"
  brand.description = "大丸松坂屋百货是日本历史悠久的高端百货商店，提供减5%优惠和餐饮代金券。"
  brand.logo_url = "https://images.unsplash.com/photo-1555529669-e69e7aa0ba9a?w=200&h=200&fit=crop"
  brand.featured = true
end

# 5. Bic Camera
bic_camera = AbroadBrand.find_or_create_by!(name: "Bic Camera") do |brand|
  brand.country = "日本"
  brand.category = "duty_free"
  brand.description = "Bic Camera是日本知名的电器连锁店，提供95折优惠。"
  brand.logo_url = "https://images.unsplash.com/photo-1550009158-9ebf69173e03?w=200&h=200&fit=crop"
  brand.featured = false
end

# 6. 科摩思药妆 (COSMOS)
cosmos = AbroadBrand.find_or_create_by!(name: "科摩思COSMOS") do |brand|
  brand.country = "日本"
  brand.category = "cosmeceuticals"
  brand.description = "科摩思药妆是日本知名的药妆连锁店，提供满额立减7%和免税服务。"
  brand.logo_url = "https://images.unsplash.com/photo-1596755389378-c31d21fd1273?w=200&h=200&fit=crop"
  brand.featured = false
end

cosmos_dotonbori = AbroadShop.find_or_create_by!(name: "科摩思-道顿堀店", abroad_brand: cosmos) do |shop|
  shop.city = "大阪"
  shop.address = "大阪市中央区道顿堀"
  shop.description = "位于大阪道顿堀商圈的药妆店。"
  shop.image_url = "https://images.unsplash.com/photo-1590559899731-a363ad00a649?w=400&h=300&fit=crop"
end

cosmos_kabukicho = AbroadShop.find_or_create_by!(name: "科摩思-歌舞伎町一丁目店", abroad_brand: cosmos) do |shop|
  shop.city = "东京"
  shop.address = "东京都新宿区歌舞伎町一丁目"
  shop.description = "位于东京新宿歌舞伎町的药妆店。"
  shop.image_url = "https://images.unsplash.com/photo-1578469645742-46cae010e5d4?w=400&h=300&fit=crop"
end

cosmos_shinsaibashi = AbroadShop.find_or_create_by!(name: "科摩思-心斋桥南店", abroad_brand: cosmos) do |shop|
  shop.city = "大阪"
  shop.address = "大阪市中央区心斋桥"
  shop.description = "位于大阪心斋桥商圈的药妆店。"
  shop.image_url = "https://images.unsplash.com/photo-1623861214041-39655848e109?w=400&h=300&fit=crop"
end

cosmos_tenjin = AbroadShop.find_or_create_by!(name: "科摩思-天神大丸店", abroad_brand: cosmos) do |shop|
  shop.city = "福岡"
  shop.address = "福冈县福冈市中央区天神"
  shop.description = "位于福冈天神大丸百货的药妆店。"
  shop.image_url = "https://images.unsplash.com/photo-1533050487297-09b450131914?w=400&h=300&fit=crop"
end

[cosmos_dotonbori, cosmos_kabukicho, cosmos_shinsaibashi, cosmos_tenjin].each do |shop|
  AbroadCoupon.find_or_create_by!(title: "满额立减7%", abroad_brand: cosmos, abroad_shop: shop) do |coupon|
    coupon.discount_type = "percentage"
    coupon.discount_value = "7"
    coupon.description = "满额立减7%"
    coupon.valid_from = Date.today
    coupon.valid_until = Date.today + 1.year
    coupon.active = true
  end
  
  AbroadCoupon.find_or_create_by!(title: "免税", abroad_brand: cosmos, abroad_shop: shop) do |coupon|
    coupon.discount_type = "tax_free"
    coupon.discount_value = "免税"
    coupon.description = "免税"
    coupon.valid_from = Date.today
    coupon.valid_until = Date.today + 1.year
    coupon.active = true
  end
end

# 7. AKAKABE PHARMACY (赤壁药妆)
akakabe = AbroadBrand.find_or_create_by!(name: "AKAKABE PHARMACY 【赤壁药妆】") do |brand|
  brand.country = "日本"
  brand.category = "cosmeceuticals"
  brand.description = "赤壁药妆是日本知名的药妆连锁店，提供92折+免税服务。"
  brand.logo_url = "https://images.unsplash.com/photo-1596755389378-c31d21fd1273?w=200&h=200&fit=crop"
  brand.featured = false
end

akakabe_osaka = AbroadShop.find_or_create_by!(name: "AKAKABE PHARMACY 【赤壁药妆】", abroad_brand: akakabe) do |shop|
  shop.city = "大阪市"
  shop.address = "大阪市中央区"
  shop.description = "位于大阪市中心的药妆店。"
  shop.image_url = "https://images.unsplash.com/photo-1596755389378-c31d21fd1273?w=400&h=300&fit=crop"
end

AbroadCoupon.find_or_create_by!(title: "可享92折+免税", abroad_brand: akakabe, abroad_shop: akakabe_osaka) do |coupon|
  coupon.discount_type = "percentage"
  coupon.discount_value = "92"
  coupon.description = "可享92折+免税"
  coupon.valid_from = Date.today
  coupon.valid_until = Date.today + 1.year
  coupon.active = true
end

# 8. 京王百货（新宿店）
keio = AbroadBrand.find_or_create_by!(name: "京王新宿店") do |brand|
  brand.country = "日本"
  brand.category = "department_store"
  brand.description = "京王百货新宿店提供95折和10%免税优惠。"
  brand.logo_url = "https://images.unsplash.com/photo-1555529669-e69e7aa0ba9a?w=200&h=200&fit=crop"
  brand.featured = false
end

keio_shinjuku = AbroadShop.find_or_create_by!(name: "京王新宿店", abroad_brand: keio) do |shop|
  shop.city = "东京"
  shop.address = "东京都新宿区西新宿"
  shop.description = "位于新宿的京王百货店。"
  shop.image_url = "https://images.unsplash.com/photo-1555529669-e69e7aa0ba9a?w=400&h=300&fit=crop"
end

AbroadCoupon.find_or_create_by!(title: "立享95折 + 10%免税", abroad_brand: keio, abroad_shop: keio_shinjuku) do |coupon|
  coupon.discount_type = "percentage"
  coupon.discount_value = "95"
  coupon.description = "立享95折 + 10%免税"
  coupon.valid_from = Date.today
  coupon.valid_until = Date.today + 1.year
  coupon.active = true
end

# 9. 小田急百货店（新宿店）
odakyu = AbroadBrand.find_or_create_by!(name: "小田急百货店（新宿店）") do |brand|
  brand.country = "日本"
  brand.category = "department_store"
  brand.description = "小田急百货新宿店提供94折和10%免税优惠。"
  brand.logo_url = "https://images.unsplash.com/photo-1555529669-e69e7aa0ba9a?w=200&h=200&fit=crop"
  brand.featured = false
end

odakyu_shinjuku = AbroadShop.find_or_create_by!(name: "小田急百货店（新宿店）", abroad_brand: odakyu) do |shop|
  shop.city = "东京"
  shop.address = "东京都新宿区西新宿"
  shop.description = "位于新宿的小田急百货店。"
  shop.image_url = "https://images.unsplash.com/photo-1555529669-e69e7aa0ba9a?w=400&h=300&fit=crop"
end

AbroadCoupon.find_or_create_by!(title: "立享94折+10%免税", abroad_brand: odakyu, abroad_shop: odakyu_shinjuku) do |coupon|
  coupon.discount_type = "percentage"
  coupon.discount_value = "94"
  coupon.description = "立享94折+10%免税"
  coupon.valid_from = Date.today
  coupon.valid_until = Date.today + 1.year
  coupon.active = true
end

puts "✓ Created #{AbroadBrand.count} brands"
puts "✓ Created #{AbroadShop.count} shops"
puts "✓ Created #{AbroadCoupon.count} coupons"
