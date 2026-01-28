# frozen_string_literal: true

# membership_products_v1 数据包
# 会员商城商品数据
#
# 用途：
# - 提供完整的商城商品测试数据
# - 覆盖各个分类和价格区间
# - 包含低价商品(少量里程+金额)和高价商品(大量里程+金额)
#
# 加载方式：
# rake validator:reset_baseline

puts "正在加载 membership_products_v1 数据包..."

# 清空现有数据
MembershipOrder.destroy_all
MembershipProduct.destroy_all

# 创建商品数据
products_data = [
  # ========== 热门商品 ==========
  # 低价商品 - 少量里程或纯金额
  {
    name: '瑞幸咖啡券 9.9元',
    slug: 'luckin-coffee-9',
    category: 'popular',
    price_cash: 9.90,
    price_mileage: 0,
    original_price: 15.00,
    sales_count: 5234,
    stock: 9999,
    rating: 4.8,
    description: '瑞幸咖啡电子券，全国门店通用',
    image_url: 'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=400',
    region: 'domestic',
    featured: true
  },
  {
    name: '蜜雪冰城 5元代金券',
    slug: 'mixue-5',
    category: 'popular',
    price_cash: 4.00,
    price_mileage: 10,
    original_price: 5.00,
    sales_count: 8923,
    stock: 9999,
    rating: 4.7,
    description: '蜜雪冰城门店通用代金券',
    image_url: 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=400',
    region: 'domestic',
    featured: true
  },
  {
    name: '肯德基早餐券',
    slug: 'kfc-breakfast',
    category: 'popular',
    price_cash: 15.00,
    price_mileage: 50,
    original_price: 25.00,
    sales_count: 3456,
    stock: 5000,
    rating: 4.9,
    description: 'KFC早餐套餐兑换券',
    image_url: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400',
    region: 'domestic',
    featured: true
  },
  {
    name: '喜茶30元代金券',
    slug: 'heytea-30',
    category: 'popular',
    price_cash: 20.00,
    price_mileage: 200,
    original_price: 30.00,
    sales_count: 2341,
    stock: 3000,
    rating: 4.8,
    description: '喜茶门店通用代金券',
    image_url: 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=400',
    region: 'domestic',
    featured: true
  },
  {
    name: '星巴克咖啡券 50元',
    slug: 'starbucks-50',
    category: 'popular',
    price_cash: 35.00,
    price_mileage: 500,
    original_price: 50.00,
    sales_count: 1876,
    stock: 2000,
    rating: 4.9,
    description: '星巴克电子礼品卡，全国门店通用',
    image_url: 'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=400',
    region: 'domestic',
    featured: true
  },
  # 中高价商品
  {
    name: '京东E卡 100元',
    slug: 'jd-100',
    category: 'popular',
    price_cash: 80.00,
    price_mileage: 1500,
    original_price: 100.00,
    sales_count: 1234,
    stock: 1000,
    rating: 4.9,
    description: '京东商城购物卡，全场通用',
    image_url: 'https://images.unsplash.com/photo-1472851294608-062f824d29cc?w=400',
    region: 'domestic',
    featured: true
  },
  {
    name: '天猫超市卡 200元',
    slug: 'tmall-200',
    category: 'popular',
    price_cash: 180.00,
    price_mileage: 3000,
    original_price: 200.00,
    sales_count: 892,
    stock: 800,
    rating: 4.8,
    description: '天猫超市购物卡，日用百货通用',
    image_url: 'https://images.unsplash.com/photo-1472851294608-062f824d29cc?w=400',
    region: 'domestic',
    featured: false
  },
  
  # ========== 年货精选 ==========
  {
    name: '三只松鼠零食大礼包',
    slug: 'snack-gift-box',
    category: 'spring_festival',
    price_cash: 68.00,
    price_mileage: 800,
    original_price: 99.00,
    sales_count: 678,
    stock: 500,
    rating: 4.7,
    description: '坚果零食组合装，过年送礼佳品',
    image_url: 'https://images.unsplash.com/photo-1599490659213-e2b9527bd087?w=400',
    region: 'domestic',
    featured: false
  },
  {
    name: '五芳斋粽子礼盒',
    slug: 'wufangzhai-zongzi',
    category: 'spring_festival',
    price_cash: 88.00,
    price_mileage: 1200,
    original_price: 128.00,
    sales_count: 456,
    stock: 400,
    rating: 4.7,
    description: '经典口味粽子礼盒，传统美味',
    image_url: 'https://images.unsplash.com/photo-1505253716362-afaea1d3d1af?w=400',
    region: 'domestic',
    featured: false
  },
  {
    name: '稻香村糕点礼盒',
    slug: 'daoxiangcun-gift',
    category: 'spring_festival',
    price_cash: 128.00,
    price_mileage: 2000,
    original_price: 188.00,
    sales_count: 345,
    stock: 300,
    rating: 4.8,
    description: '老字号糕点，传统年味',
    image_url: 'https://images.unsplash.com/photo-1607623814075-e51df1bdc82f?w=400',
    region: 'domestic',
    featured: true
  },
  {
    name: '阿胶糕礼盒 500g',
    slug: 'ejiao-gift-box',
    category: 'spring_festival',
    price_cash: 268.00,
    price_mileage: 5000,
    original_price: 358.00,
    sales_count: 234,
    stock: 200,
    rating: 4.8,
    description: '东阿阿胶，养生佳品',
    image_url: 'https://images.unsplash.com/photo-1607623814075-e51df1bdc82f?w=400',
    region: 'domestic',
    featured: false
  },
  {
    name: '茅台飞天53度 500ml',
    slug: 'maotai-feitian',
    category: 'spring_festival',
    price_cash: 1999.00,
    price_mileage: 30000,
    original_price: 2499.00,
    sales_count: 89,
    stock: 50,
    rating: 5.0,
    description: '国酒茅台，送礼佳品',
    image_url: 'https://images.unsplash.com/photo-1569529465841-dfecdab7503b?w=400',
    region: 'domestic',
    featured: true
  },
  
  # ========== 品质露营 ==========
  {
    name: '便携式野餐垫',
    slug: 'picnic-mat',
    category: 'quality',
    price_cash: 39.00,
    price_mileage: 200,
    original_price: 79.00,
    sales_count: 1234,
    stock: 1000,
    rating: 4.6,
    description: '防水防潮，轻便易携带',
    image_url: 'https://images.unsplash.com/photo-1504280390367-361c6d9f38f4?w=400',
    region: 'domestic',
    featured: false
  },
  {
    name: '户外保温杯 500ml',
    slug: 'thermos-bottle',
    category: 'quality',
    price_cash: 89.00,
    price_mileage: 500,
    original_price: 149.00,
    sales_count: 890,
    stock: 800,
    rating: 4.7,
    description: '304不锈钢，24小时保温',
    image_url: 'https://images.unsplash.com/photo-1602143407151-7111542de6e8?w=400',
    region: 'domestic',
    featured: false
  },
  {
    name: '便携式卡式炉',
    slug: 'portable-stove',
    category: 'quality',
    price_cash: 159.00,
    price_mileage: 1500,
    original_price: 289.00,
    sales_count: 678,
    stock: 500,
    rating: 4.6,
    description: '野外烹饪必备，安全可靠',
    image_url: 'https://images.unsplash.com/photo-1476231682828-37e571bc172f?w=400',
    region: 'domestic',
    featured: false
  },
  {
    name: '户外折叠桌椅套装',
    slug: 'outdoor-table-chair-set',
    category: 'quality',
    price_cash: 299.00,
    price_mileage: 3500,
    original_price: 599.00,
    sales_count: 345,
    stock: 300,
    rating: 4.7,
    description: '铝合金材质，轻便耐用',
    image_url: 'https://images.unsplash.com/photo-1478131143081-80f7f84ca84d?w=400',
    region: 'domestic',
    featured: false
  },
  {
    name: 'Snow Peak 钛合金餐具套装',
    slug: 'snowpeak-titanium-set',
    category: 'quality',
    price_cash: 599.00,
    price_mileage: 8000,
    original_price: 899.00,
    sales_count: 234,
    stock: 200,
    rating: 5.0,
    description: '轻量便携，耐用环保',
    image_url: 'https://images.unsplash.com/photo-1478131143081-80f7f84ca84d?w=400',
    region: 'domestic',
    featured: true
  },
  {
    name: 'Coleman 4人帐篷',
    slug: 'coleman-tent-4p',
    category: 'quality',
    price_cash: 799.00,
    price_mileage: 10000,
    original_price: 1299.00,
    sales_count: 167,
    stock: 150,
    rating: 4.9,
    description: '防雨透气，搭建简便',
    image_url: 'https://images.unsplash.com/photo-1504280390367-361c6d9f38f4?w=400',
    region: 'domestic',
    featured: true
  },
  
  # ========== 户外运动 ==========
  {
    name: '运动水壶 750ml',
    slug: 'sports-bottle',
    category: 'outdoor',
    price_cash: 49.00,
    price_mileage: 300,
    original_price: 89.00,
    sales_count: 1567,
    stock: 2000,
    rating: 4.6,
    description: 'Tritan材质，便携防漏',
    image_url: 'https://images.unsplash.com/photo-1523362628745-0c100150b504?w=400',
    region: 'domestic',
    featured: false
  },
  {
    name: '速干运动毛巾',
    slug: 'quick-dry-towel',
    category: 'outdoor',
    price_cash: 29.00,
    price_mileage: 150,
    original_price: 59.00,
    sales_count: 2345,
    stock: 3000,
    rating: 4.5,
    description: '超细纤维，吸水速干',
    image_url: 'https://images.unsplash.com/photo-1556906781-9a412961c28c?w=400',
    region: 'domestic',
    featured: false
  },
  {
    name: '户外头灯',
    slug: 'headlamp',
    category: 'outdoor',
    price_cash: 79.00,
    price_mileage: 600,
    original_price: 149.00,
    sales_count: 789,
    stock: 800,
    rating: 4.7,
    description: 'LED强光，续航持久',
    image_url: 'https://images.unsplash.com/photo-1513201099705-a9746e1e201f?w=400',
    region: 'domestic',
    featured: false
  },
  {
    name: 'Black Diamond 登山杖',
    slug: 'black-diamond-poles',
    category: 'outdoor',
    price_cash: 349.00,
    price_mileage: 4000,
    original_price: 599.00,
    sales_count: 456,
    stock: 400,
    rating: 4.7,
    description: '碳纤维材质，超轻便携',
    image_url: 'https://images.unsplash.com/photo-1526976668912-1a811878dd37?w=400',
    region: 'international',
    featured: false
  },
  {
    name: 'Salomon 越野跑鞋',
    slug: 'salomon-trail-shoes',
    category: 'outdoor',
    price_cash: 699.00,
    price_mileage: 8000,
    original_price: 1199.00,
    sales_count: 567,
    stock: 300,
    rating: 4.8,
    description: '抓地力强，耐磨防滑',
    image_url: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400',
    region: 'international',
    featured: true
  },
  {
    name: 'Osprey 登山包 60L',
    slug: 'osprey-backpack-60l',
    category: 'outdoor',
    price_cash: 1099.00,
    price_mileage: 15000,
    original_price: 1799.00,
    sales_count: 234,
    stock: 200,
    rating: 4.9,
    description: '大容量背负系统，舒适透气',
    image_url: 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=400',
    region: 'international',
    featured: true
  },
  {
    name: 'Suunto 户外手表',
    slug: 'suunto-outdoor-watch',
    category: 'outdoor',
    price_cash: 1799.00,
    price_mileage: 20000,
    original_price: 2499.00,
    sales_count: 189,
    stock: 150,
    rating: 4.9,
    description: 'GPS导航，气压高度计',
    image_url: 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400',
    region: 'international',
    featured: true
  },
  {
    name: 'Arc\'teryx 冲锋衣',
    slug: 'arcteryx-jacket',
    category: 'outdoor',
    price_cash: 2899.00,
    price_mileage: 35000,
    original_price: 3999.00,
    sales_count: 145,
    stock: 100,
    rating: 5.0,
    description: 'GORE-TEX面料，专业防护',
    image_url: 'https://images.unsplash.com/photo-1551488831-00ddcb6c6bd3?w=400',
    region: 'international',
    featured: true
  }
]

MembershipProduct.insert_all(products_data)

puts "✓ 已创建 #{products_data.length} 个商品"
puts "  - 低价商品(10-100元): #{products_data.count { |p| p[:price_cash] < 100 }} 个"
puts "  - 中价商品(100-500元): #{products_data.count { |p| p[:price_cash] >= 100 && p[:price_cash] < 500 }} 个"
puts "  - 高价商品(500元以上): #{products_data.count { |p| p[:price_cash] >= 500 }} 个"
puts "  - 纯金额商品(0里程): #{products_data.count { |p| p[:price_mileage] == 0 }} 个"
puts "  - 少量里程商品(1-1000里程): #{products_data.count { |p| p[:price_mileage] > 0 && p[:price_mileage] <= 1000 }} 个"
puts "  - 大量里程商品(1000里程以上): #{products_data.count { |p| p[:price_mileage] > 1000 }} 个"
puts "✓ 数据包加载完成"
