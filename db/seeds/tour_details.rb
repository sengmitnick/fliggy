# 为旅游产品添加详细信息：套餐、行程、评价等

puts "📦 添加旅游产品详情数据..."

# 找到上海天文馆产品
shanghai_tianwenguan = TourGroupProduct.find_by(title: '上海+上海天文馆+一日游+随时可定+上午下午场大咖讲解')

if shanghai_tianwenguan
  puts "处理产品: #{shanghai_tianwenguan.title}"
  
  # 更新产品详情字段
  shanghai_tianwenguan.update!(
    reward_points: 34,
    requires_merchant_confirm: true,
    merchant_confirm_hours: 48,
    success_rate_high: true,
    description: %{
      <h3>天津梦远全体员工期待为您服务！！！</h3>
      <p>1.上海天文馆一日研学营，服务人次30000+，出票率保证！</p>
      <p>2.讲解时间：分为全天讲解、上午场讲解、下午场讲解</p>
      <p>3.多套餐可选，出行无忧。梦远团队会全部安排到位！</p>
      <p>4.坞馆内电影可以指定场次，会尽量帮您安排连座！</p>
      <p>5.讲解服务直正做到您满意，天文协会讲师为您讲解天文馆</p>
      <p>可选上午/下午（全部讲师带团经验500场次+）！</p>
    }.strip,
    cost_includes: %{景点门票：上海天文馆

补充说明：
1、套餐是天文馆讲解散拼，天文深度讲解精致小团。
2、套餐为一个人的价格，儿人出行就拍几份。
3、避免影响您的行程，下单请咨询客服。
4、馆内任何需要自费项目均由旅客承担！只承担套餐内的相关费用。}.strip,
    cost_excludes: %{补充说明：未提及的费用都不包含}.strip,
    safety_notice: %{1. 为普及安全旅游知识和文明旅游公约，开心、顺利度过您的假期，请务必认真阅读《旅游安全手册》，并切实遵守。

2. 高原地区旅游、户外旅游以及部分室内游乐项目（包括但不限于潜水、游泳、漂流、滑冰、滑雪、冲浪、探险、热气球、高山索道等项目），均存在一定风险。平台现从特殊人群须知、旅游活动风险防范两方面制定了《安全防护指南》，请您仔细阅读！参与前请根据自身条件详询商家，并充分参考专业机构的相关公告和建议，量力而行确保安全。同时严格按照项目要求，做足安全防护准备，并请积极关注天气变化，如遇恶劣天气，请严格遵守服务方安排，切勿冒险。

3. 为了更全面地保障您的人身安全，平台强烈建议您出游时投保个人险种。出行过程中，请注意人身和财产安全。租车出游请遵守当地交通规则，谨慎驾驶。

4. 请详细阅读商家于商品详情页面上发布的内容，特别是预订须知、退改规则、安全告知等与您的出行密切相关的条款。若有任何疑问，请及时联系商家确认。}.strip,
    booking_notice: %{1.价格是一个人的价格，几个人拍几件
2.下单后不要自己动手去购票，不要下单多个店铺（因以上两点会导致出行失败）
3.此套餐都是自行前往
4.天文馆门票检票时间上午9:30-16:00点}.strip,
    insurance_notice: %{该商品不赠送保险，飞猪建议您自行购买出行保险，为您的出行提供更全面的保障。}.strip,
    cancellation_policy: %{【买家违约】订单生效后，行程未出行，因买家原因取消，则按照《飞猪国内跟团游退改规则》中的退款标准进行退款。}.strip,
    price_explanation: %{划线价格：未划线价格：折扣}.strip,
    group_tour_notice: %{本商品行程一定不会采用拼团方式拼至其他旅行社成团}.strip,
    custom_tour_available: true
  )
  
  # 删除旧套餐（如果存在）
  shanghai_tianwenguan.tour_packages.destroy_all
  
  # 创建套餐：同一路线的不同出发时间和配置
  puts "  创建套餐..."
  packages = [
    {
      name: '上午场标准套餐',
      price: 68,
      child_price: 48,
      purchase_count: 320,
      description: '含天文馆门票+专业讲解|游玩约2.5小时|上午9:30出发|最多15人精品小团',
      is_featured: false,
      display_order: 1
    },
    {
      name: '上午场豪华套餐',
      price: 88,
      child_price: 68,
      purchase_count: 450,
      description: '含天文馆门票+球幕影院IMAX+专业讲解|游玩约3小时|上午9:30出发|赠送纪念品|最多15人精品小团',
      is_featured: true,
      display_order: 2
    },
    {
      name: '下午场标准套餐',
      price: 68,
      child_price: 48,
      purchase_count: 280,
      description: '含天文馆门票+专业讲解|游玩约2.5小时|下午14:00出发|最多15人精品小团',
      is_featured: false,
      display_order: 3
    }
  ]
  
  packages.each do |pkg_attrs|
    shanghai_tianwenguan.tour_packages.create!(pkg_attrs)
  end
  
  puts "  ✓ 创建了 #{shanghai_tianwenguan.tour_packages.count} 个套餐"
  
  # 创建行程
  puts "  创建行程..."
  itinerary = {
    day_number: 1,
    title: '上海天文馆',
    attractions: [
      {
        name: '上海天文馆',
        tags: ['全国科技馆景点榜·第1名', '宇宙空间体验', '有趣天文奇观'],
        review_count: 72,
        images: [
          'https://images.unsplash.com/photo-1464037866556-6812c9d1c72e?w=600',
          'https://images.unsplash.com/photo-1550592704-6c76defa9985?w=600'
        ],
        description: '上海天文馆独特的建筑设计，源自设计师对轨道运动的不断探索。建筑整体采用螺旋形态，寓意天体运行轨迹，与展陈主题相得益彰。',
        cost_note: '包含且无需自费'
      }
    ],
    assembly_point: '此套餐为全天参观，自由行到天文馆参观即可',
    assembly_details: '集合地址：此套餐为全天参观，自由行到天文馆参观即可
集合详情：此套餐是包含全天门票，不含其他。自由行到天文馆参观即可（检票时间为：9:30-16:00）',
    disassembly_point: '馆内自行解散',
    disassembly_details: '详情：自行解散即可',
    transportation: '无行程用车',
    service_info: '最多15人 | 含导游服务',
    duration_minutes: 150
  }
  
  shanghai_tianwenguan.tour_itinerary_days.create!(itinerary)
  
  puts "  ✓ 创建了行程信息"
  
  # 创建评价
  puts "  创建评价..."
  
  # 创建一些测试用户用于评价
  test_users = []
  5.times do |i|
    user = User.find_or_create_by!(email: "test_reviewer_#{i}@example.com") do |u|
      u.name = "用户#{13588260252 + i}"
      u.password = "password123"
      u.verified = true
    end
    test_users << user
  end
  
  reviews = [
    {
      user: test_users[0],
      rating: 5.0,
      guide_attitude: 5.0,
      meal_quality: 5.0,
      itinerary_arrangement: 4.9,
      travel_transportation: 4.9,
      comment: '这次天文馆半日游非常满意。小安老师值得推荐，讲解的风趣幽默，小朋友听的非常入迷，2个半小时全程在线～',
      is_featured: true,
      helpful_count: 156,
      created_at: 3.days.ago
    },
    {
      user: test_users[1],
      rating: 4.9,
      guide_attitude: 5.0,
      meal_quality: 4.8,
      itinerary_arrangement: 4.9,
      travel_transportation: 4.9,
      comment: '讲解员非常专业，对天文知识了如指掌，孩子学到了很多知识，强烈推荐！',
      is_featured: true,
      helpful_count: 89,
      created_at: 5.days.ago
    },
    {
      user: test_users[2],
      rating: 4.8,
      guide_attitude: 4.7,
      meal_quality: 4.9,
      itinerary_arrangement: 4.8,
      travel_transportation: 4.8,
      comment: '天文馆很震撼，讲解服务也很到位，就是人有点多，排队时间较长。',
      is_featured: false,
      helpful_count: 45,
      created_at: 7.days.ago
    },
    {
      user: test_users[3],
      rating: 5.0,
      guide_attitude: 5.0,
      meal_quality: 5.0,
      itinerary_arrangement: 5.0,
      travel_transportation: 5.0,
      comment: '服务超级好，讲解老师很有耐心，全程陪同，孩子玩得很开心！',
      is_featured: true,
      helpful_count: 123,
      created_at: 10.days.ago
    },
    {
      user: test_users[4],
      rating: 4.7,
      guide_attitude: 4.8,
      meal_quality: 4.6,
      itinerary_arrangement: 4.7,
      travel_transportation: 4.7,
      comment: '整体不错，性价比高，就是时间有点紧张，如果能延长一点就更好了。',
      is_featured: false,
      helpful_count: 32,
      created_at: 12.days.ago
    }
  ]
  
  reviews.each do |review_attrs|
    shanghai_tianwenguan.tour_reviews.create!(review_attrs)
  end
  
  puts "  ✓ 创建了 #{shanghai_tianwenguan.tour_reviews.count} 条评价"
  
  # 更新产品评分（基于真实评价）
  avg_rating = shanghai_tianwenguan.tour_reviews.average(:rating).round(1)
  shanghai_tianwenguan.update!(rating: avg_rating)
  
  puts "  ✓ 更新产品评分为 #{avg_rating}"
  
  puts "✅ 完成产品详情数据添加"
else
  puts "❌ 未找到上海天文馆产品"
end
