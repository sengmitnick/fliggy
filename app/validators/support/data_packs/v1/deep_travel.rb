# frozen_string_literal: true


# 清理现有深度旅行数据
DeepTravelProduct.destroy_all
DeepTravelGuide.destroy_all

# ==================== 深度旅行讲师数据 ====================

timestamp = Time.current
guides_data = [
  {
    name: "叶强",
    title: "潜水教学",
    description: "PADI国际潜水教练，拥有10年海洋探索经验。专注于为初学者提供安全、专业的潜水培训服务，带你探索神秘的海底世界。",
    follower_count: 8234,
    experience_years: 10,
    specialties: "PADI潜水教练认证、水下摄影、海洋生物识别、潜水装备维护",
    price: 580.00,
    served_count: 1256,
    rank: 1,
    rating: 4.9,
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "张雪梅",
    title: "滑雪教学",
    description: "国家级滑雪教练,曾参加多次国际滑雪赛事。擅长单板、双板教学，为不同水平的学员提供个性化训练方案。",
    follower_count: 6789,
    experience_years: 8,
    specialties: "单板滑雪、双板滑雪、雪地安全知识、滑雪装备选择",
    price: 680.00,
    served_count: 892,
    rank: 2,
    rating: 4.8,
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "李文博",
    title: "文化讲解",
    description: "资深文化学者，专注于历史文化遗产讲解。带你深入了解每个城市背后的故事，让旅行更有温度和深度。",
    follower_count: 12456,
    experience_years: 15,
    specialties: "历史文化讲解、古建筑鉴赏、民俗文化、博物馆导览",
    price: 480.00,
    served_count: 2134,
    rank: 3,
    rating: 4.9,
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "王小美",
    title: "跟拍人像",
    description: "职业人像摄影师，擅长旅行跟拍和人像写真。用镜头记录你的美好时刻，让每一次旅行都留下难忘的回忆。",
    follower_count: 15678,
    experience_years: 6,
    specialties: "旅行跟拍、人像摄影、风光摄影、后期修图",
    price: 880.00,
    served_count: 1678,
    rank: 4,
    rating: 4.9,
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "赵大伟",
    title: "当地司导",
    description: "本地资深司导，熟悉城市的每一个角落。提供包车服务和深度游线路规划，让你的旅行更轻松自在。",
    follower_count: 5432,
    experience_years: 12,
    specialties: "本地司导、线路规划、美食推荐、住宿建议",
    price: 550.00,
    served_count: 3456,
    rank: 5,
    rating: 4.7,
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "陈思雨",
    title: "瑜伽冥想",
    description: "国际瑜伽联盟认证教练，专注于旅行瑜伽和正念冥想。在大自然中找到身心平衡，让旅行成为一种修行。",
    follower_count: 9876,
    experience_years: 7,
    specialties: "哈他瑜伽、流瑜伽、正念冥想、呼吸练习",
    price: 420.00,
    served_count: 1123,
    rank: 6,
    rating: 4.8,
    featured: false,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "刘浩然",
    title: "攀岩教学",
    description: "国家级攀岩教练，多次参加国内外攀岩赛事。为攀岩爱好者提供专业指导，挑战自我，征服高峰。",
    follower_count: 4567,
    experience_years: 9,
    specialties: "室内攀岩、户外攀岩、抱石、绳索技术",
    price: 650.00,
    served_count: 678,
    rank: 7,
    rating: 4.7,
    featured: false,
    created_at: timestamp,
    updated_at: timestamp
  }
]

# 批量插入讲师
DeepTravelGuide.insert_all(guides_data)

# 重新加载以获取ID映射
guides_map = DeepTravelGuide.pluck(:name, :id).to_h

# ==================== 深度旅行产品数据 ====================

products_data = []

# 叶强 - 潜水教学产品
ye_qiang_id = guides_map["叶强"]
products_data.concat([
  {
    deep_travel_guide_id: ye_qiang_id,
    title: "三亚蜈支洲岛潜水体验",
    subtitle: "PADI体验潜水课程",
    location: "三亚",
    price: 580.00,
    sales_count: 328,
    description: "在美丽的蜈支洲岛进行PADI体验潜水，专业教练一对一指导，探索神秘的海底世界。包含全套装备和保险。",
    itinerary: "上午：理论知识讲解\n中午：浅水区练习\n下午：深水区探索\n全程约4小时",
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    deep_travel_guide_id: ye_qiang_id,
    title: "涠洲岛自由潜水培训",
    subtitle: "AIDA自由潜水课程",
    location: "北海",
    price: 1280.00,
    sales_count: 156,
    description: "在广西涠洲岛学习自由潜水，体验憋气下潜的极致魅力。3天课程，从入门到进阶。",
    itinerary: "Day1：呼吸训练+泳池练习\nDay2：海洋理论+浅海实践\nDay3：深度挑战+技巧提升",
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    deep_travel_guide_id: ye_qiang_id,
    title: "厦门近海潜水探秘",
    subtitle: "海底生物观察课程",
    location: "厦门",
    price: 480.00,
    sales_count: 267,
    description: "在厦门海域进行浮潜和潜水体验，观察丰富的海底生物，适合亲子家庭。",
    itinerary: "上午：基础培训\n下午：海底探索\n全程约3小时",
    featured: false,
    created_at: timestamp,
    updated_at: timestamp
  }
])

# 张雪梅 - 滑雪教学产品
zhang_xuemei_id = guides_map["张雪梅"]
products_data.concat([
  {
    deep_travel_guide_id: zhang_xuemei_id,
    title: "崇礼万龙滑雪场私教课",
    subtitle: "单板/双板一对一教学",
    location: "北京",
    price: 680.00,
    sales_count: 234,
    description: "在崇礼万龙滑雪场享受私人教练服务，无论初学者还是进阶者，都能快速提升技巧。",
    itinerary: "上午：技术讲解+平地练习\n中午：休息\n下午：雪道实战练习\n全程约5小时",
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    deep_travel_guide_id: zhang_xuemei_id,
    title: "长白山滑雪冬令营",
    subtitle: "3天滑雪集训",
    location: "长白山",
    price: 1980.00,
    sales_count: 89,
    description: "在长白山度假区进行3天滑雪集训，系统学习滑雪技巧，提升雪上能力。",
    itinerary: "Day1：基础入门+初级雪道\nDay2：中级技巧+雪道挑战\nDay3：高级练习+自由滑行",
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    deep_travel_guide_id: zhang_xuemei_id,
    title: "亚布力滑雪周末营",
    subtitle: "单板进阶课程",
    location: "哈尔滨",
    price: 1280.00,
    sales_count: 145,
    description: "专注单板进阶技巧，在亚布力顶级雪场度过充实的周末。",
    itinerary: "Day1：转弯技巧精进\nDay2：跳跃和花式入门",
    featured: false,
    created_at: timestamp,
    updated_at: timestamp
  }
])

# 李文博 - 文化讲解产品
li_wenbo_id = guides_map["李文博"]
products_data.concat([
  {
    deep_travel_guide_id: li_wenbo_id,
    title: "北京故宫深度文化游",
    subtitle: "跟随历史学者游故宫",
    location: "北京",
    price: 480.00,
    sales_count: 567,
    description: "资深历史学者带你深入了解故宫的历史文化，揭秘皇家建筑背后的故事。",
    itinerary: "上午：太和殿、中和殿、保和殿讲解\n中午：午餐休息\n下午：御花园、珍宝馆讲解\n全程约6小时",
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    deep_travel_guide_id: li_wenbo_id,
    title: "西安古城墙文化漫步",
    subtitle: "唐文化深度体验",
    location: "西安",
    price: 380.00,
    sales_count: 423,
    description: "漫步西安古城墙，听专家讲述千年古都的故事，感受盛唐文化的魅力。",
    itinerary: "下午：城墙徒步+历史讲解\n傍晚：观看城墙灯光秀\n全程约4小时",
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    deep_travel_guide_id: li_wenbo_id,
    title: "苏州园林建筑艺术",
    subtitle: "江南园林鉴赏",
    location: "苏州",
    price: 350.00,
    sales_count: 312,
    description: "专业讲解江南园林建筑艺术，领略苏州园林的独特魅力。",
    itinerary: "上午：拙政园深度游览\n下午：留园+狮子林讲解\n全程约5小时",
    featured: false,
    created_at: timestamp,
    updated_at: timestamp
  }
])

# 王小美 - 跟拍人像产品
wang_xiaomei_id = guides_map["王小美"]
products_data.concat([
  {
    deep_travel_guide_id: wang_xiaomei_id,
    title: "三亚海滩婚纱写真",
    subtitle: "专业婚纱摄影跟拍",
    location: "三亚",
    price: 1280.00,
    sales_count: 234,
    description: "在三亚美丽的海滩拍摄婚纱照，专业摄影师全程跟拍，留下浪漫时刻。",
    itinerary: "上午：海滩外景拍摄\n中午：休息+换装\n下午：椰林+礁石拍摄\n全程约6小时，精修30张",
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    deep_travel_guide_id: wang_xiaomei_id,
    title: "杭州西湖古风人像",
    subtitle: "汉服旅拍",
    location: "杭州",
    price: 880.00,
    sales_count: 456,
    description: "穿上汉服漫步西湖，专业摄影师捕捉你的每一个美好瞬间。",
    itinerary: "上午：西湖景区汉服拍摄\n下午：断桥+雷峰塔取景\n全程约4小时，精修20张",
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    deep_travel_guide_id: wang_xiaomei_id,
    title: "成都街拍城市写真",
    subtitle: "都市时尚人像",
    location: "成都",
    price: 680.00,
    sales_count: 378,
    description: "在成都最潮的街区拍摄时尚大片，展现你的个性魅力。",
    itinerary: "下午：春熙路+太古里街拍\n傍晚：九眼桥夜景人像\n全程约3小时，精修15张",
    featured: false,
    created_at: timestamp,
    updated_at: timestamp
  }
])

# 赵大伟 - 当地司导产品
zhao_dawei_id = guides_map["赵大伟"]
products_data.concat([
  {
    deep_travel_guide_id: zhao_dawei_id,
    title: "云南大理丽江深度包车游",
    subtitle: "6天5晚私家团",
    location: "大理",
    price: 3980.00,
    sales_count: 123,
    description: "资深司导带你游遍云南精华景点，深度体验当地文化，品尝地道美食。",
    itinerary: "Day1-2：大理古城+洱海\nDay3-4：丽江古城+玉龙雪山\nDay5-6：泸沽湖+返程",
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    deep_travel_guide_id: zhao_dawei_id,
    title: "厦门鼓浪屿一日包车游",
    subtitle: "轻松玩转厦门",
    location: "厦门",
    price: 550.00,
    sales_count: 567,
    description: "本地司导带你一天玩遍厦门精华景点，含接送和美食推荐。",
    itinerary: "上午：鼓浪屿游览\n中午：品尝地道海鲜\n下午：环岛路+南普陀寺\n全程约8小时",
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  }
])

# 陈思雨 - 瑜伽冥想产品
chen_siyu_id = guides_map["陈思雨"]
products_data.concat([
  {
    deep_travel_guide_id: chen_siyu_id,
    title: "三亚海边瑜伽静修",
    subtitle: "3天2晚身心疗愈之旅",
    location: "三亚",
    price: 1680.00,
    sales_count: 89,
    description: "在三亚海边进行瑜伽练习和冥想，让身心得到深度放松和疗愈。",
    itinerary: "每日：日出瑜伽+正念冥想+呼吸练习\n晚间：海滩冥想+星空放松\n3天深度静修",
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    deep_travel_guide_id: chen_siyu_id,
    title: "杭州禅修瑜伽体验",
    subtitle: "周末身心放松",
    location: "杭州",
    price: 880.00,
    sales_count: 156,
    description: "在杭州幽静的禅院中练习瑜伽，体验禅修的宁静与智慧。",
    itinerary: "Day1：瑜伽基础+行禅\nDay2：流瑜伽+茶禅\n2天1晚",
    featured: false,
    created_at: timestamp,
    updated_at: timestamp
  }
])

# 刘浩然 - 攀岩教学产品
liu_haoran_id = guides_map["刘浩然"]
products_data.concat([
  {
    deep_travel_guide_id: liu_haoran_id,
    title: "阳朔户外攀岩体验",
    subtitle: "喀斯特地貌攀岩",
    location: "桂林",
    price: 680.00,
    sales_count: 78,
    description: "在阳朔著名的喀斯特地貌岩壁上攀岩，挑战自我，征服高峰。",
    itinerary: "上午：攀岩技巧培训\n下午：户外岩壁实战\n全程约5小时",
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    deep_travel_guide_id: liu_haoran_id,
    title: "北京室内攀岩课程",
    subtitle: "零基础攀岩培训",
    location: "北京",
    price: 450.00,
    sales_count: 234,
    description: "在专业室内攀岩馆学习攀岩技巧，从零开始掌握攀岩运动。",
    itinerary: "理论讲解+装备使用+攀爬练习\n全程约3小时",
    featured: false,
    created_at: timestamp,
    updated_at: timestamp
  }
])

# 批量插入产品
DeepTravelProduct.insert_all(products_data)

puts "\n✅ 深度旅行数据初始化完成！"
puts "  - 讲师总数: #{DeepTravelGuide.count}"
puts "  - 产品总数: #{DeepTravelProduct.count}"
puts "  - 特色产品: #{DeepTravelProduct.where(featured: true).count}"
