puts "正在初始化深度旅行数据..."

# 清理现有深度旅行数据
DeepTravelProduct.destroy_all
DeepTravelGuide.destroy_all

# ==================== 深度旅行讲师数据 ====================
puts "正在创建深度旅行讲师..."

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
    avatar_url: "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400"
  },
  {
    name: "张雪梅",
    title: "滑雪教学",
    description: "国家级滑雪教练，曾参加多次国际滑雪赛事。擅长单板、双板教学，为不同水平的学员提供个性化训练方案。",
    follower_count: 6789,
    experience_years: 8,
    specialties: "单板滑雪、双板滑雪、雪地安全知识、滑雪装备选择",
    price: 680.00,
    served_count: 892,
    rank: 2,
    rating: 4.8,
    featured: true,
    avatar_url: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400"
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
    avatar_url: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400"
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
    avatar_url: "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400"
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
    avatar_url: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400"
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
    avatar_url: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400"
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
    avatar_url: "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400"
  }
]

guides = []
guides_data.each do |guide_data|
  guide = DeepTravelGuide.create!(guide_data.except(:avatar_url))
  guides << guide
  puts "创建讲师: #{guide.name} - #{guide.title}"
end

puts "创建了 #{guides.count} 位深度旅行讲师"

# ==================== 深度旅行产品数据 ====================
puts "正在创建深度旅行产品..."

# 为每位讲师创建多个产品（按地区分布）
products_data = [
  # 叶强 - 潜水教学产品
  {
    guide_name: "叶强",
    products: [
      {
        title: "三亚蜈支洲岛潜水体验",
        subtitle: "PADI体验潜水课程",
        location: "三亚",
        price: 580.00,
        sales_count: 328,
        description: "在美丽的蜈支洲岛进行PADI体验潜水，专业教练一对一指导，探索神秘的海底世界。包含全套装备和保险。",
        itinerary: "上午：理论知识讲解\n中午：浅水区练习\n下午：深水区探索\n全程约4小时",
        featured: true,
        images: [
          "https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=800",
          "https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=800"
        ]
      },
      {
        title: "涠洲岛自由潜水培训",
        subtitle: "AIDA自由潜水课程",
        location: "北海",
        price: 1280.00,
        sales_count: 156,
        description: "在广西涠洲岛学习自由潜水，体验憋气下潜的极致魅力。3天课程，从入门到进阶。",
        itinerary: "Day1：呼吸训练+泳池练习\nDay2：海洋理论+浅海实践\nDay3：深度挑战+技巧提升",
        featured: true,
        images: [
          "https://images.unsplash.com/photo-1682687220742-aba13b6e50ba?w=800",
          "https://images.unsplash.com/photo-1583212292454-1fe6229603b7?w=800"
        ]
      },
      {
        title: "厦门近海潜水探秘",
        subtitle: "海底生物观察课程",
        location: "厦门",
        price: 480.00,
        sales_count: 267,
        description: "在厦门海域进行浮潜和潜水体验，观察丰富的海底生物，适合亲子家庭。",
        itinerary: "上午：基础培训\n下午：海底探索\n全程约3小时",
        featured: false,
        images: [
          "https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=800"
        ]
      }
    ]
  },
  
  # 张雪梅 - 滑雪教学产品
  {
    guide_name: "张雪梅",
    products: [
      {
        title: "崇礼万龙滑雪场私教课",
        subtitle: "单板/双板一对一教学",
        location: "北京",
        price: 680.00,
        sales_count: 234,
        description: "在崇礼万龙滑雪场享受私人教练服务，无论初学者还是进阶者，都能快速提升技巧。",
        itinerary: "上午：技术讲解+平地练习\n中午：休息\n下午：雪道实战练习\n全程约5小时",
        featured: true,
        images: [
          "https://images.unsplash.com/photo-1551698618-1dfe5d97d256?w=800",
          "https://images.unsplash.com/photo-1605540436563-5bca919ae766?w=800"
        ]
      },
      {
        title: "长白山滑雪冬令营",
        subtitle: "3天滑雪集训",
        location: "长白山",
        price: 1980.00,
        sales_count: 89,
        description: "在长白山度假区进行3天滑雪集训，系统学习滑雪技巧，提升雪上能力。",
        itinerary: "Day1：基础入门+初级雪道\nDay2：中级技巧+雪道挑战\nDay3：高级练习+自由滑行",
        featured: true,
        images: [
          "https://images.unsplash.com/photo-1565540579050-f3fede8d04b6?w=800",
          "https://images.unsplash.com/photo-1609137144813-7d9921338f24?w=800"
        ]
      },
      {
        title: "亚布力滑雪周末营",
        subtitle: "单板进阶课程",
        location: "哈尔滨",
        price: 1280.00,
        sales_count: 145,
        description: "专注单板进阶技巧，在亚布力顶级雪场度过充实的周末。",
        itinerary: "Day1：转弯技巧精进\nDay2：跳跃和花式入门",
        featured: false,
        images: [
          "https://images.unsplash.com/photo-1551698618-1dfe5d97d256?w=800"
        ]
      }
    ]
  },
  
  # 李文博 - 文化讲解产品
  {
    guide_name: "李文博",
    products: [
      {
        title: "北京故宫深度文化游",
        subtitle: "跟随历史学者游故宫",
        location: "北京",
        price: 480.00,
        sales_count: 567,
        description: "资深历史学者带你深入了解故宫的历史文化，揭秘皇家建筑背后的故事。",
        itinerary: "上午：太和殿、中和殿、保和殿讲解\n中午：午餐休息\n下午：御花园、珍宝馆讲解\n全程约6小时",
        featured: true,
        images: [
          "https://images.unsplash.com/photo-1508804185872-d7badad00f7d?w=800",
          "https://images.unsplash.com/photo-1547981609-4b6bfe67ca0b?w=800"
        ]
      },
      {
        title: "西安古城墙文化漫步",
        subtitle: "唐文化深度体验",
        location: "西安",
        price: 380.00,
        sales_count: 423,
        description: "漫步西安古城墙，听专家讲述千年古都的故事，感受盛唐文化的魅力。",
        itinerary: "下午：城墙徒步+历史讲解\n傍晚：观看城墙灯光秀\n全程约4小时",
        featured: true,
        images: [
          "https://images.unsplash.com/photo-1565967511849-76a60a516170?w=800",
          "https://images.unsplash.com/photo-1590397952249-c2e4eb888f58?w=800"
        ]
      },
      {
        title: "苏州园林艺术鉴赏",
        subtitle: "江南园林美学课",
        location: "苏州",
        price: 420.00,
        sales_count: 312,
        description: "在拙政园、留园等经典园林中，学习中国古典园林艺术，领略江南文化之美。",
        itinerary: "上午：拙政园深度讲解\n下午：留园+狮子林鉴赏\n全程约5小时",
        featured: true,
        images: [
          "https://images.unsplash.com/photo-1525181245258-0baae3b325ad?w=800",
          "https://images.unsplash.com/photo-1590069261209-f8e9b8642343?w=800"
        ]
      },
      {
        title: "成都宽窄巷子民俗游",
        subtitle: "巴蜀文化体验",
        location: "成都",
        price: 320.00,
        sales_count: 389,
        description: "走进宽窄巷子，品味成都的慢生活，了解巴蜀文化的独特魅力。",
        itinerary: "下午：宽窄巷子漫步+讲解\n傍晚：品茶+川剧变脸\n全程约4小时",
        featured: false,
        images: [
          "https://images.unsplash.com/photo-1590069261209-f8e9b8642343?w=800"
        ]
      }
    ]
  },
  
  # 王小美 - 跟拍人像产品
  {
    guide_name: "王小美",
    products: [
      {
        title: "厦门鼓浪屿文艺写真",
        subtitle: "海边小清新写真",
        location: "厦门",
        price: 880.00,
        sales_count: 456,
        description: "在浪漫的鼓浪屿拍摄文艺清新写真，专业摄影师全程跟拍，精修50张底片。",
        itinerary: "上午：鼓浪屿各景点拍摄\n下午：海边日落写真\n全程约4小时",
        featured: true,
        images: [
          "https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=800",
          "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=800"
        ]
      },
      {
        title: "丽江古城旅拍套餐",
        subtitle: "民族风情写真",
        location: "丽江",
        price: 1280.00,
        sales_count: 298,
        description: "在丽江古城和玉龙雪山拍摄民族风情写真，提供民族服装，记录你的丽江之旅。",
        itinerary: "Day1：古城写真拍摄\nDay2：玉龙雪山外景拍摄\n全程2天",
        featured: true,
        images: [
          "https://images.unsplash.com/photo-1512632578888-169bbbc64f33?w=800",
          "https://images.unsplash.com/photo-1496412705862-e0088f16f791?w=800"
        ]
      },
      {
        title: "三亚海景婚纱照",
        subtitle: "海边浪漫婚纱写真",
        location: "三亚",
        price: 2580.00,
        sales_count: 234,
        description: "在三亚最美海滩拍摄婚纱照，包含婚纱礼服、造型设计、全程跟拍和精修。",
        itinerary: "全天拍摄：\n上午：海滩外景\n下午：酒店内景+日落海景\n全程约8小时",
        featured: true,
        images: [
          "https://images.unsplash.com/photo-1519741497674-611481863552?w=800",
          "https://images.unsplash.com/photo-1515934751635-c81c6bc9a2d8?w=800"
        ]
      },
      {
        title: "大理洱海环海写真",
        subtitle: "网红打卡地写真",
        location: "大理",
        price: 980.00,
        sales_count: 367,
        description: "在洱海边各大网红打卡点拍摄写真，白桌子、透明球、玻璃船应有尽有。",
        itinerary: "全天拍摄：\n多个网红打卡点拍摄\n全程约6小时",
        featured: true,
        images: [
          "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800",
          "https://images.unsplash.com/photo-1501594907352-04cda38ebc29?w=800"
        ]
      }
    ]
  },
  
  # 赵大伟 - 当地司导产品
  {
    guide_name: "赵大伟",
    products: [
      {
        title: "北京包车深度游",
        subtitle: "6-8小时包车服务",
        location: "北京",
        price: 550.00,
        sales_count: 678,
        description: "经验丰富的本地司导，带你游览北京各大景点，规划最优路线，分享地道美食。",
        itinerary: "可选行程：\n故宫-天坛-颐和园\n或 长城-明十三陵\n或 定制路线",
        featured: true,
        images: [
          "https://images.unsplash.com/photo-1508804185872-d7badad00f7d?w=800",
          "https://images.unsplash.com/photo-1583415283968-f1a97cb4cd64?w=800"
        ]
      },
      {
        title: "成都周边深度游",
        subtitle: "都江堰+青城山包车",
        location: "成都",
        price: 680.00,
        sales_count: 456,
        description: "从成都出发，游览都江堰、青城山等周边景点，本地司导讲解，轻松舒适。",
        itinerary: "全天行程：\n上午：都江堰景区\n中午：本地美食\n下午：青城山\n全程约10小时",
        featured: true,
        images: [
          "https://images.unsplash.com/photo-1590069261209-f8e9b8642343?w=800",
          "https://images.unsplash.com/photo-1528127269322-539801943592?w=800"
        ]
      },
      {
        title: "桂林山水包车游",
        subtitle: "漓江-阳朔深度游",
        location: "桂林",
        price: 580.00,
        sales_count: 389,
        description: "桂林山水甲天下，本地司导带你深度游览漓江和阳朔，感受最美山水风光。",
        itinerary: "全天行程：\n漓江游船-十里画廊-西街\n全程约8小时",
        featured: false,
        images: [
          "https://images.unsplash.com/photo-1549024994-7c050c7c9889?w=800"
        ]
      }
    ]
  },
  
  # 陈思雨 - 瑜伽冥想产品
  {
    guide_name: "陈思雨",
    products: [
      {
        title: "大理古城瑜伽静修",
        subtitle: "3天2夜瑜伽冥想营",
        location: "大理",
        price: 1680.00,
        sales_count: 178,
        description: "在风花雪月的大理，进行身心静修。每天晨起洱海边瑜伽，日落时分冥想，找回内心的平静。",
        itinerary: "Day1：入营+基础瑜伽\nDay2：进阶练习+正念冥想\nDay3：自由练习+分享交流",
        featured: true,
        images: [
          "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800",
          "https://images.unsplash.com/photo-1588286840104-8957b019727f?w=800"
        ]
      },
      {
        title: "三亚海边瑜伽课",
        subtitle: "日出海边瑜伽",
        location: "三亚",
        price: 420.00,
        sales_count: 267,
        description: "在三亚海滩上迎接日出，进行唤醒身心的瑜伽练习，感受海风和晨光的洗礼。",
        itinerary: "清晨：海边瑜伽练习\n全程约2小时",
        featured: true,
        images: [
          "https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800",
          "https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=800"
        ]
      }
    ]
  },
  
  # 刘浩然 - 攀岩教学产品
  {
    guide_name: "刘浩然",
    products: [
      {
        title: "阳朔户外攀岩体验",
        subtitle: "初级攀岩课程",
        location: "桂林",
        price: 650.00,
        sales_count: 156,
        description: "在世界级攀岩胜地阳朔，体验户外攀岩的魅力。专业教练指导，全套安全装备。",
        itinerary: "上午：攀岩理论+装备使用\n下午：岩壁实战练习\n全程约5小时",
        featured: true,
        images: [
          "https://images.unsplash.com/photo-1522163182402-834f871fd851?w=800",
          "https://images.unsplash.com/photo-1564769625905-50e93615e769?w=800"
        ]
      },
      {
        title: "北京室内攀岩训练",
        subtitle: "攀岩技巧提升班",
        location: "北京",
        price: 480.00,
        sales_count: 234,
        description: "在专业室内攀岩馆进行系统训练，提升攀岩技巧和体能。",
        itinerary: "每次课程：\n热身+技巧讲解+实战练习\n全程约3小时",
        featured: false,
        images: [
          "https://images.unsplash.com/photo-1522163723043-478ef79f5bb8?w=800"
        ]
      }
    ]
  }
]

# 创建产品
products_created = 0
products_data.each do |guide_products|
  guide = DeepTravelGuide.find_by(name: guide_products[:guide_name])
  next unless guide
  
  guide_products[:products].each do |product_data|
    product = guide.deep_travel_products.create!(product_data.except(:images))
    products_created += 1
    puts "创建产品: #{product.title} (#{product.location}) - ¥#{product.price}"
  end
end

puts "创建了 #{products_created} 个深度旅行产品"
puts "深度旅行数据初始化完成！"
puts ""
puts "数据统计："
puts "- 讲师总数: #{DeepTravelGuide.count}"
puts "- 产品总数: #{DeepTravelProduct.count}"
puts "- 特色讲师: #{DeepTravelGuide.featured.count}"
puts "- 特色产品: #{DeepTravelProduct.featured.count}"
puts ""
puts "覆盖城市："
DeepTravelProduct.pluck(:location).uniq.sort.each do |location|
  count = DeepTravelProduct.where(location: location).count
  puts "  #{location}: #{count} 个产品"
end
