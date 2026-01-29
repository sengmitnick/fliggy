# frozen_string_literal: true

# 深度旅行 - 景点多讲解员数据包
# 为所有地区标签提供完整的讲解员和产品数据
#
# 用途：
# - 展示同一景点的多个讲解员选择
# - 支持讲解员切换器功能
# - 覆盖所有地区标签：境内精选（北京+华东+华中+陕西）、境外精选、北京、华东、华中、陕西
#
# 加载方式：
# rails runner "load Rails.root.join('app/validators/support/data_packs/v1/deep_travel_venues.rb')"


timestamp = Time.current

# ==================== 北京地区 ====================

beijing_guides = [
  # 故宫博物院 - 5位讲解员
  {
    name: "叶强",
    venue: "故宫博物院",
    title: "全国博物馆景点榜",
    description: "北京导游协会金牌导游 故宫认证讲解员 北京卫视《紫禁城》节目特邀讲解员 擅长皇家文化、建筑艺术讲解",
    follower_count: 100,
    experience_years: 10,
    specialties: "皇家文化、建筑艺术、文物鉴赏、历史典故",
    price: 192.06,
    served_count: 10000,
    rank: 1,
    rating: 4.9,
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "张成松",
    venue: "故宫博物院",
    title: "全国博物馆景点榜",
    description: "国家金牌导游, 全国百佳优秀导游, 北京导游大赛银奖, 北京卫视《我爱北京》特邀嘉宾",
    follower_count: 9,
    experience_years: 10,
    specialties: "明清历史、皇家礼仪、古建筑、文物收藏",
    price: 158.00,
    served_count: 8000,
    rank: 2,
    rating: 4.8,
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "李明华",
    venue: "故宫博物院",
    title: "全国博物馆景点榜",
    description: "故宫资深讲解员，专注故宫文化研究20年，擅长讲述皇帝私生活和后宫秘闻",
    follower_count: 15,
    experience_years: 20,
    specialties: "后宫文化、皇帝秘史、宫廷生活、珍宝鉴赏",
    price: 228.00,
    served_count: 15000,
    rank: 1,
    rating: 4.9,
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "王晓红",
    venue: "故宫博物院",
    title: "全国博物馆景点榜",
    description: "北京市优秀导游，故宫御用讲解员，中央电视台《国宝档案》特邀嘉宾",
    follower_count: 12,
    experience_years: 15,
    specialties: "国宝文物、书画收藏、瓷器鉴赏、钟表文化",
    price: 198.00,
    served_count: 12000,
    rank: 1,
    rating: 4.8,
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "刘建国",
    venue: "故宫博物院",
    title: "全国博物馆景点榜",
    description: "故宫博物院特聘讲解员，北京史研究专家，讲解风格幽默风趣，深受游客喜爱",
    follower_count: 8,
    experience_years: 12,
    specialties: "北京史、建筑风水、皇家园林、民间传说",
    price: 168.00,
    served_count: 9000,
    rank: 1,
    rating: 4.7,
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  # 颐和园 - 3位讲解员
  {
    name: "赵雅琴",
    venue: "颐和园",
    title: "北京皇家园林榜",
    description: "北京市特级导游，颐和园专家讲解员，专注皇家园林文化研究15年",
    follower_count: 10,
    experience_years: 15,
    specialties: "皇家园林、建筑美学、山水造景、慈禧太后",
    price: 138.00,
    served_count: 9500,
    rank: 1,
    rating: 4.8,
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "孙文博",
    venue: "颐和园",
    title: "北京皇家园林榜",
    description: "园林建筑专业背景，颐和园特聘讲解员，擅长讲述园林设计理念",
    follower_count: 8,
    experience_years: 10,
    specialties: "园林设计、建筑布局、山水画意、历史典故",
    price: 128.00,
    served_count: 7500,
    rank: 2,
    rating: 4.7,
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "李园林",
    venue: "颐和园",
    title: "北京皇家园林榜",
    description: "清史研究专家，讲解风格生动有趣，特别擅长讲述慈禧太后的故事",
    follower_count: 11,
    experience_years: 12,
    specialties: "清代历史、慈禧轶事、宫廷秘闻、文物珍藏",
    price: 148.00,
    served_count: 8800,
    rank: 1,
    rating: 4.8,
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  }
]

DeepTravelGuide.insert_all(beijing_guides)

# 重新加载以获取ID
beijing_guide_ids = DeepTravelGuide.where(venue: ["故宫博物院", "颐和园"]).pluck(:name, :id).to_h

# 北京地区产品数据
beijing_products = [
  # 故宫博物院产品
  {
    deep_travel_guide_id: beijing_guide_ids["叶强"],
    title: "【出票超快 | 名师讲解】北京故宫博物院文化之旅【赠耳机+故宫地图】",
    subtitle: "故宫博物院 北京导游协会金牌导游",
    location: "北京",
    price: 192.06,
    sales_count: 156,
    description: "北京导游协会金牌导游，故宫认证讲解员，带你深度游览紫禁城，了解600年皇家文化。",
    itinerary: "上午：午门-太和殿-中和殿-保和殿\n中午：休息\n下午：乾清宫-交泰殿-坤宁宫-御花园\n全程约6小时",
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    deep_travel_guide_id: beijing_guide_ids["张成松"],
    title: "【金牌导游】北京故宫深度文化游【3小时精华讲解】",
    subtitle: "故宫博物院 国家金牌导游带队",
    location: "北京",
    price: 158.00,
    sales_count: 128,
    description: "国家金牌导游带你游故宫，深入浅出讲解明清历史和皇家文化。",
    itinerary: "精华路线：午门-三大殿-后三宫-珍宝馆\n全程约3小时",
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    deep_travel_guide_id: beijing_guide_ids["李明华"],
    title: "【资深讲解】故宫后宫秘史探秘【揭秘皇家生活】",
    subtitle: "故宫博物院 20年资深讲解员",
    location: "北京",
    price: 228.00,
    sales_count: 98,
    description: "20年故宫研究专家，带你探秘后宫秘史，了解真实的皇家生活。",
    itinerary: "专题路线：后宫-妃嫔居所-御花园-珍宝馆\n全程约4小时",
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    deep_travel_guide_id: beijing_guide_ids["王晓红"],
    title: "【国宝鉴赏】故宫文物珍宝深度讲解【含珍宝馆】",
    subtitle: "故宫博物院 文物鉴赏专家",
    location: "北京",
    price: 198.00,
    sales_count: 112,
    description: "央视《国宝档案》嘉宾，带你鉴赏故宫珍宝，了解文物背后的故事。",
    itinerary: "专题路线：珍宝馆-钟表馆-书画馆-瓷器馆\n全程约4小时",
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    deep_travel_guide_id: beijing_guide_ids["刘建国"],
    title: "【风趣幽默】故宫轻松游【适合亲子家庭】",
    subtitle: "故宫博物院 幽默讲解员",
    location: "北京",
    price: 168.00,
    sales_count: 145,
    description: "讲解风格幽默风趣，让历史变得有趣易懂，特别适合带孩子的家庭。",
    itinerary: "经典路线：三大殿-后三宫-御花园\n全程约3.5小时",
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  # 颐和园产品
  {
    deep_travel_guide_id: beijing_guide_ids["赵雅琴"],
    title: "【皇家园林】颐和园深度游【含长廊+佛香阁】",
    subtitle: "颐和园 特级导游讲解",
    location: "北京",
    price: 138.00,
    sales_count: 88,
    description: "特级导游带你游览颐和园，深入了解皇家园林建筑和慈禧太后的故事。",
    itinerary: "东宫门-仁寿殿-长廊-石舫-佛香阁-昆明湖\n全程约3.5小时",
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    deep_travel_guide_id: beijing_guide_ids["孙文博"],
    title: "【园林美学】颐和园建筑艺术鉴赏【专业讲解】",
    subtitle: "颐和园 园林建筑专家",
    location: "北京",
    price: 128.00,
    sales_count: 76,
    description: "从建筑美学角度欣赏颐和园，了解中国古典园林的设计精髓。",
    itinerary: "园林布局-山水造景-建筑艺术-文化内涵\n全程约3小时",
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    deep_travel_guide_id: beijing_guide_ids["李园林"],
    title: "【慈禧秘史】颐和园宫廷故事【生动有趣】",
    subtitle: "颐和园 清史专家讲解",
    location: "北京",
    price: 148.00,
    sales_count: 92,
    description: "生动讲述慈禧太后在颐和园的故事，揭秘晚清宫廷生活。",
    itinerary: "慈禧居所-宫廷秘闻-历史典故-珍藏文物\n全程约3.5小时",
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  }
]

DeepTravelProduct.insert_all(beijing_products)

# ==================== 陕西地区 ====================

shaanxi_guides = [
  # 秦始皇帝陵博物院 - 3位讲解员
  {
    name: "惟真",
    venue: "秦始皇帝陵博物院",
    title: "西安亲子景点榜",
    description: "西安市金牌导游&高级导游, 西安石油大学学工部导师, 旅游管理专业高级讲师",
    follower_count: 10,
    experience_years: 10,
    specialties: "秦文化、兵马俑、考古知识、历史讲解",
    price: 78.00,
    served_count: 8000,
    rank: 1,
    rating: 4.9,
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "李秦风",
    venue: "秦始皇帝陵博物院",
    title: "西安亲子景点榜",
    description: "陕西省优秀导游，兵马俑专家，曾为多国元首提供讲解服务",
    follower_count: 12,
    experience_years: 15,
    specialties: "秦始皇陵、兵马俑修复、青铜器、秦代历史",
    price: 98.00,
    served_count: 12000,
    rank: 1,
    rating: 4.9,
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "张文物",
    venue: "秦始皇帝陵博物院",
    title: "西安亲子景点榜",
    description: "考古专业出身，兵马俑博物馆特聘讲解员，擅长讲述考古发现过程",
    follower_count: 8,
    experience_years: 8,
    specialties: "考古发现、文物修复、兵马俑制作工艺、秦代军事",
    price: 88.00,
    served_count: 6000,
    rank: 1,
    rating: 4.8,
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  # 西安城墙 - 3位讲解员
  {
    name: "王古城",
    venue: "西安城墙",
    title: "西安历史文化榜",
    description: "西安历史文化专家，城墙景区金牌讲解员，擅长讲述古都历史",
    follower_count: 9,
    experience_years: 12,
    specialties: "古代军事、城墙建筑、西安历史、唐代文化",
    price: 68.00,
    served_count: 7500,
    rank: 1,
    rating: 4.7,
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "刘长安",
    venue: "西安城墙",
    title: "西安历史文化榜",
    description: "唐史研究者，讲解风格幽默风趣，让历史变得生动有趣",
    follower_count: 7,
    experience_years: 8,
    specialties: "唐朝历史、古代建筑、民间传说、文化典故",
    price: 58.00,
    served_count: 6200,
    rank: 2,
    rating: 4.6,
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "赵明清",
    venue: "西安城墙",
    title: "西安历史文化榜",
    description: "建筑学专业背景，专注古代城墙建筑研究，讲解专业深入",
    follower_count: 6,
    experience_years: 10,
    specialties: "古代建筑、城防工程、建筑美学、历史变迁",
    price: 78.00,
    served_count: 6800,
    rank: 1,
    rating: 4.8,
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  }
]

DeepTravelGuide.insert_all(shaanxi_guides)

# 重新加载以获取ID
shaanxi_guide_ids = DeepTravelGuide.where(venue: ["秦始皇帝陵博物院", "西安城墙"]).pluck(:name, :id).to_h

# 陕西地区产品数据
shaanxi_products = [
  # 秦始皇帝陵博物院产品
  {
    deep_travel_guide_id: shaanxi_guide_ids["惟真"],
    title: "【金牌导游】秦始皇兵马俑深度讲解【2小时精华游】",
    subtitle: "秦始皇帝陵博物院 金牌导游",
    location: "陕西",
    price: 78.00,
    sales_count: 189,
    description: "西安市金牌导游，带你深入了解秦始皇陵和兵马俑的历史文化。",
    itinerary: "1号坑-2号坑-3号坑-铜车马展厅\n全程约2小时",
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    deep_travel_guide_id: shaanxi_guide_ids["李秦风"],
    title: "【VIP讲解】兵马俑专家深度游【含秦始皇陵】",
    subtitle: "秦始皇帝陵博物院 兵马俑专家",
    location: "陕西",
    price: 98.00,
    sales_count: 156,
    description: "曾为多国元首讲解，带你全面了解秦文化和兵马俑的奥秘。",
    itinerary: "秦始皇陵-兵马俑三个坑-铜车马-文物修复展\n全程约3小时",
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    deep_travel_guide_id: shaanxi_guide_ids["张文物"],
    title: "【考古视角】兵马俑发现与修复【适合学生】",
    subtitle: "秦始皇帝陵博物院 考古专业讲解",
    location: "陕西",
    price: 88.00,
    sales_count: 167,
    description: "考古专业背景，从考古学角度讲述兵马俑的发现和修复过程。",
    itinerary: "考古发现过程-文物修复-兵马俑制作工艺\n全程约2.5小时",
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  # 西安城墙产品
  {
    deep_travel_guide_id: shaanxi_guide_ids["王古城"],
    title: "【古都风貌】西安城墙文化游【含骑行+讲解】",
    subtitle: "西安城墙 金牌讲解员",
    location: "陕西",
    price: 68.00,
    sales_count: 134,
    description: "金牌讲解员带你游览古城墙，了解西安古都历史和城墙文化。",
    itinerary: "城墙历史-古代军事-建筑特色-骑行体验\n全程约2.5小时",
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    deep_travel_guide_id: shaanxi_guide_ids["刘长安"],
    title: "【风趣讲解】西安城墙唐代故事【适合家庭】",
    subtitle: "西安城墙 幽默讲解员",
    location: "陕西",
    price: 58.00,
    sales_count: 145,
    description: "幽默风趣的讲解风格，让历史变得生动有趣，特别适合亲子游。",
    itinerary: "唐代历史-民间传说-文化典故-城墙漫步\n全程约2小时",
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    deep_travel_guide_id: shaanxi_guide_ids["赵明清"],
    title: "【建筑美学】西安城墙建筑艺术【专业讲解】",
    subtitle: "西安城墙 建筑专家",
    location: "陕西",
    price: 78.00,
    sales_count: 122,
    description: "建筑学专家视角，深入讲解古代城墙的建筑工艺和防御功能。",
    itinerary: "城防工程-建筑结构-修复工艺-历史变迁\n全程约2.5小时",
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  }
]

DeepTravelProduct.insert_all(shaanxi_products)

# ==================== 华东地区 ====================

huadong_guides = [
  # 上海外滩 - 3位讲解员
  {
    name: "陈海派",
    venue: "上海外滩",
    title: "上海必游景点榜",
    description: "上海市特级导游，外滩历史文化专家，擅长讲述十里洋场的繁华往事",
    follower_count: 12,
    experience_years: 15,
    specialties: "近代史、建筑文化、上海滩故事、租界历史",
    price: 128.00,
    served_count: 11000,
    rank: 1,
    rating: 4.9,
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "王国际",
    venue: "上海外滩",
    title: "上海必游景点榜",
    description: "建筑学硕士，外滩建筑群研究专家，深谙万国建筑博览会的精髓",
    follower_count: 10,
    experience_years: 12,
    specialties: "建筑艺术、欧式风格、历史建筑、城市规划",
    price: 138.00,
    served_count: 9500,
    rank: 1,
    rating: 4.8,
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "张老洋房",
    venue: "上海外滩",
    title: "上海必游景点榜",
    description: "上海本地人，讲解风格生动幽默，特别擅长讲述老上海的市井故事",
    follower_count: 9,
    experience_years: 10,
    specialties: "上海文化、民国往事、名人轶事、老上海风情",
    price: 118.00,
    served_count: 8800,
    rank: 2,
    rating: 4.7,
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  # 苏州园林 - 3位讲解员
  {
    name: "吴园林",
    venue: "苏州园林",
    title: "江南园林榜",
    description: "苏州园林研究专家，园林局特聘讲解员，深谙江南园林造园艺术",
    follower_count: 11,
    experience_years: 18,
    specialties: "园林艺术、造园手法、文化内涵、诗词典故",
    price: 148.00,
    served_count: 10500,
    rank: 1,
    rating: 4.9,
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "周姑苏",
    venue: "苏州园林",
    title: "江南园林榜",
    description: "苏州大学园林专业讲师，讲解专业细致，擅长园林美学鉴赏",
    follower_count: 8,
    experience_years: 10,
    specialties: "园林设计、美学鉴赏、建筑布局、山水意境",
    price: 128.00,
    served_count: 8200,
    rank: 2,
    rating: 4.8,
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "沈江南",
    venue: "苏州园林",
    title: "江南园林榜",
    description: "江南文化传承人，讲解风格诗意优雅，让游客感受江南韵味",
    follower_count: 10,
    experience_years: 14,
    specialties: "江南文化、诗词文化、历史典故、园林意境",
    price: 138.00,
    served_count: 9300,
    rank: 1,
    rating: 4.8,
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  }
]

DeepTravelGuide.insert_all(huadong_guides)

# 重新加载以获取ID
huadong_guide_ids = DeepTravelGuide.where(venue: ["上海外滩", "苏州园林"]).pluck(:name, :id).to_h

# 华东地区产品数据
huadong_products = [
  # 上海外滩产品
  {
    deep_travel_guide_id: huadong_guide_ids["陈海派"],
    title: "【十里洋场】上海外滩历史文化游【万国建筑】",
    subtitle: "上海外滩 特级导游讲解",
    location: "华东",
    price: 128.00,
    sales_count: 167,
    description: "特级导游带你游览外滩，深入了解十里洋场的繁华历史和万国建筑。",
    itinerary: "外滩历史-建筑群-租界往事-黄浦江夜景\n全程约2.5小时",
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    deep_travel_guide_id: huadong_guide_ids["王国际"],
    title: "【建筑鉴赏】外滩万国建筑博览【专业讲解】",
    subtitle: "上海外滩 建筑专家",
    location: "华东",
    price: 138.00,
    sales_count: 145,
    description: "建筑学硕士带你鉴赏外滩建筑群，了解各种欧式建筑风格的精髓。",
    itinerary: "建筑风格-设计理念-历史背景-文化融合\n全程约2.5小时",
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    deep_travel_guide_id: huadong_guide_ids["张老洋房"],
    title: "【老上海故事】外滩民国往事【生动有趣】",
    subtitle: "上海外滩 本地导游",
    location: "华东",
    price: 118.00,
    sales_count: 178,
    description: "上海本地人讲述老上海的市井故事，幽默风趣，让历史活起来。",
    itinerary: "民国往事-名人轶事-老上海风情-文化变迁\n全程约2小时",
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  # 苏州园林产品
  {
    deep_travel_guide_id: huadong_guide_ids["吴园林"],
    title: "【江南韵味】苏州园林艺术鉴赏【含拙政园】",
    subtitle: "苏州园林 园林专家",
    location: "华东",
    price: 148.00,
    sales_count: 156,
    description: "园林研究专家带你深度游览苏州园林，领略江南造园艺术的精髓。",
    itinerary: "拙政园-造园手法-诗词典故-文化内涵\n全程约3小时",
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    deep_travel_guide_id: huadong_guide_ids["周姑苏"],
    title: "【园林美学】苏州园林设计解析【专业讲座】",
    subtitle: "苏州园林 大学讲师",
    location: "华东",
    price: 128.00,
    sales_count: 134,
    description: "大学讲师专业讲解，从美学角度解析江南园林的设计精妙。",
    itinerary: "园林设计-美学鉴赏-建筑布局-山水意境\n全程约2.5小时",
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    deep_travel_guide_id: huadong_guide_ids["沈江南"],
    title: "【诗意江南】苏州园林文化游【含狮子林】",
    subtitle: "苏州园林 文化传承人",
    location: "华东",
    price: 138.00,
    sales_count: 148,
    description: "江南文化传承人带你感受园林诗意，体验真正的江南韵味。",
    itinerary: "狮子林-诗词文化-历史典故-园林意境\n全程约3小时",
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  }
]

DeepTravelProduct.insert_all(huadong_products)

# ==================== 华中地区 ====================

huazhong_guides = [
  # 武汉黄鹤楼 - 3位讲解员
  {
    name: "李楚天",
    venue: "武汉黄鹤楼",
    title: "武汉必游景点榜",
    description: "武汉市金牌导游，黄鹤楼文化专家，擅长讲述三国历史和诗词文化",
    follower_count: 10,
    experience_years: 12,
    specialties: "三国文化、诗词典故、楚文化、长江文明",
    price: 88.00,
    served_count: 8500,
    rank: 1,
    rating: 4.8,
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "周长江",
    venue: "武汉黄鹤楼",
    title: "武汉必游景点榜",
    description: "历史学硕士，特别擅长讲述黄鹤楼的历代诗词和文化内涵",
    follower_count: 8,
    experience_years: 10,
    specialties: "诗词文化、历史典故、文学鉴赏、建筑历史",
    price: 78.00,
    served_count: 7200,
    rank: 2,
    rating: 4.7,
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "张江城",
    venue: "武汉黄鹤楼",
    title: "武汉必游景点榜",
    description: "武汉本地讲解员，讲解风格幽默亲切，深受游客喜爱",
    follower_count: 9,
    experience_years: 8,
    specialties: "武汉文化、民间传说、历史故事、地方风情",
    price: 68.00,
    served_count: 6800,
    rank: 2,
    rating: 4.6,
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  # 长沙岳麓书院 - 3位讲解员
  {
    name: "胡湘江",
    venue: "长沙岳麓书院",
    title: "湖南文化景点榜",
    description: "湖南大学历史系教授，岳麓书院特聘讲解专家，湖湘文化研究者",
    follower_count: 11,
    experience_years: 20,
    specialties: "湖湘文化、书院历史、理学思想、教育史",
    price: 118.00,
    served_count: 9500,
    rank: 1,
    rating: 4.9,
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "王岳麓",
    venue: "长沙岳麓书院",
    title: "湖南文化景点榜",
    description: "文史专业背景，书院文化爱好者，讲解深入浅出，通俗易懂",
    follower_count: 8,
    experience_years: 10,
    specialties: "书院文化、古代教育、理学思想、历史名人",
    price: 98.00,
    served_count: 7500,
    rank: 2,
    rating: 4.7,
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "陈惟楚",
    venue: "长沙岳麓书院",
    title: "湖南文化景点榜",
    description: "长沙本地文化学者，对湖湘文化有深入研究，讲解生动有趣",
    follower_count: 9,
    experience_years: 12,
    specialties: "湖湘名人、文化传承、历史典故、建筑文化",
    price: 108.00,
    served_count: 8200,
    rank: 1,
    rating: 4.8,
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  }
]

DeepTravelGuide.insert_all(huazhong_guides)

# 重新加载以获取ID
huazhong_guide_ids = DeepTravelGuide.where(venue: ["武汉黄鹤楼", "长沙岳麓书院"]).pluck(:name, :id).to_h

# 华中地区产品数据
huazhong_products = [
  # 武汉黄鹤楼产品
  {
    deep_travel_guide_id: huazhong_guide_ids["李楚天"],
    title: "【千古名楼】黄鹤楼文化游【含长江大桥】",
    subtitle: "武汉黄鹤楼 金牌导游",
    location: "华中",
    price: 88.00,
    sales_count: 145,
    description: "金牌导游带你游览黄鹤楼，深入了解三国文化和历代诗词典故。",
    itinerary: "黄鹤楼历史-诗词文化-长江大桥-楚文化\n全程约2.5小时",
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    deep_travel_guide_id: huazhong_guide_ids["周长江"],
    title: "【诗词鉴赏】黄鹤楼诗词文化【深度讲解】",
    subtitle: "武汉黄鹤楼 历史学硕士",
    location: "华中",
    price: 78.00,
    sales_count: 128,
    description: "历史学硕士深度讲解黄鹤楼诗词文化，感受千年文学魅力。",
    itinerary: "历代诗词-文化内涵-文学鉴赏-建筑历史\n全程约2小时",
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    deep_travel_guide_id: huazhong_guide_ids["张江城"],
    title: "【武汉故事】黄鹤楼民间传说【轻松有趣】",
    subtitle: "武汉黄鹤楼 本地讲解员",
    location: "华中",
    price: 68.00,
    sales_count: 156,
    description: "本地讲解员幽默讲述武汉故事和黄鹤楼传说，适合家庭游。",
    itinerary: "民间传说-历史故事-武汉文化-地方风情\n全程约2小时",
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  # 长沙岳麓书院产品
  {
    deep_travel_guide_id: huazhong_guide_ids["胡湘江"],
    title: "【千年学府】岳麓书院文化深度游【大学教授讲解】",
    subtitle: "长沙岳麓书院 湖南大学教授",
    location: "华中",
    price: 118.00,
    sales_count: 134,
    description: "湖南大学教授专业讲解，深入了解书院文化和湖湘文化精髓。",
    itinerary: "书院历史-理学思想-教育传统-湖湘名人\n全程约3小时",
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    deep_travel_guide_id: huazhong_guide_ids["王岳麓"],
    title: "【书院文化】岳麓书院历史讲解【通俗易懂】",
    subtitle: "长沙岳麓书院 文史专家",
    location: "华中",
    price: 98.00,
    sales_count: 122,
    description: "文史专家深入浅出讲解书院文化，让古代教育历史变得通俗易懂。",
    itinerary: "书院文化-古代教育-理学思想-历史名人\n全程约2.5小时",
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    deep_travel_guide_id: huazhong_guide_ids["陈惟楚"],
    title: "【湖湘文化】岳麓书院文化探秘【含爱晚亭】",
    subtitle: "长沙岳麓书院 文化学者",
    location: "华中",
    price: 108.00,
    sales_count: 138,
    description: "本地文化学者讲述湖湘文化传承，游览书院和爱晚亭。",
    itinerary: "书院-爱晚亭-湖湘名人-文化传承\n全程约2.5小时",
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  }
]

DeepTravelProduct.insert_all(huazhong_products)

# ==================== 境外精选 ====================

abroad_guides = [
  # 东京浅草寺 - 3位讲解员
  {
    name: "田中美纪",
    venue: "东京浅草寺",
    title: "东京热门景点榜",
    description: "日本国家认证导游，浅草寺文化专家，中日双语讲解，了解中日文化差异",
    follower_count: 15,
    experience_years: 12,
    specialties: "日本佛教、江户文化、传统建筑、和食文化",
    price: 188.00,
    served_count: 12000,
    rank: 1,
    rating: 4.9,
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "佐藤健太",
    venue: "东京浅草寺",
    title: "东京热门景点榜",
    description: "东京本地导游，讲解风格幽默风趣，擅长讲述江户时代的故事",
    follower_count: 12,
    experience_years: 10,
    specialties: "江户历史、民间传说、和服文化、日本礼仪",
    price: 168.00,
    served_count: 9500,
    rank: 2,
    rating: 4.8,
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "山田花子",
    venue: "东京浅草寺",
    title: "东京热门景点榜",
    description: "和服文化爱好者，特别擅长讲解日本传统文化和礼仪",
    follower_count: 10,
    experience_years: 8,
    specialties: "和服文化、茶道、传统礼仪、节日庆典",
    price: 158.00,
    served_count: 8200,
    rank: 2,
    rating: 4.7,
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  # 巴黎卢浮宫 - 3位讲解员
  {
    name: "玛丽·杜邦",
    venue: "巴黎卢浮宫",
    title: "巴黎必游景点榜",
    description: "艺术史博士，卢浮宫认证讲解员，精通法国艺术史和文艺复兴",
    follower_count: 18,
    experience_years: 15,
    specialties: "艺术鉴赏、文艺复兴、法国历史、雕塑绘画",
    price: 228.00,
    served_count: 15000,
    rank: 1,
    rating: 4.9,
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "皮埃尔·马丁",
    venue: "巴黎卢浮宫",
    title: "巴黎必游景点榜",
    description: "巴黎资深导游，擅长讲述卢浮宫的历史和艺术珍品背后的故事",
    follower_count: 14,
    experience_years: 12,
    specialties: "博物馆历史、艺术珍品、法国文化、宫廷历史",
    price: 198.00,
    served_count: 11500,
    rank: 2,
    rating: 4.8,
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "安娜·罗兰",
    venue: "巴黎卢浮宫",
    title: "巴黎必游景点榜",
    description: "艺术学院讲师，讲解专业细致，让艺术变得通俗易懂",
    follower_count: 12,
    experience_years: 10,
    specialties: "艺术教育、绘画技法、艺术流派、美学鉴赏",
    price: 188.00,
    served_count: 9800,
    rank: 1,
    rating: 4.7,
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  }
]

DeepTravelGuide.insert_all(abroad_guides)

# 重新加载以获取ID
abroad_guide_ids = DeepTravelGuide.where(venue: ["东京浅草寺", "巴黎卢浮宫"]).pluck(:name, :id).to_h

# 境外精选产品数据
abroad_products = [
  # 东京浅草寺产品
  {
    deep_travel_guide_id: abroad_guide_ids["田中美纪"],
    title: "【中日双语】东京浅草寺文化游【含和服体验】",
    subtitle: "东京浅草寺 国家认证导游",
    location: "境外精选",
    price: 188.00,
    sales_count: 189,
    description: "日本国家认证导游，中日双语讲解，深入了解日本佛教和江户文化。",
    itinerary: "浅草寺-雷门-仲见世商店街-和服体验\n全程约3小时",
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    deep_travel_guide_id: abroad_guide_ids["佐藤健太"],
    title: "【江户风情】浅草寺历史文化【本地导游】",
    subtitle: "东京浅草寺 本地导游",
    location: "境外精选",
    price: 168.00,
    sales_count: 167,
    description: "东京本地导游幽默讲解，带你感受江户时代的历史风情。",
    itinerary: "江户历史-民间传说-和服文化-日本礼仪\n全程约2.5小时",
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    deep_travel_guide_id: abroad_guide_ids["山田花子"],
    title: "【和服文化】浅草寺传统礼仪【含茶道体验】",
    subtitle: "东京浅草寺 和服文化专家",
    location: "境外精选",
    price: 158.00,
    sales_count: 145,
    description: "和服文化专家讲解日本传统礼仪，体验正宗茶道文化。",
    itinerary: "和服文化-茶道体验-传统礼仪-节日庆典\n全程约2.5小时",
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  # 巴黎卢浮宫产品
  {
    deep_travel_guide_id: abroad_guide_ids["玛丽·杜邦"],
    title: "【艺术殿堂】卢浮宫深度艺术鉴赏【艺术史博士】",
    subtitle: "巴黎卢浮宫 艺术史博士",
    location: "境外精选",
    price: 228.00,
    sales_count: 178,
    description: "艺术史博士专业讲解，深入鉴赏卢浮宫艺术珍品和文艺复兴杰作。",
    itinerary: "蒙娜丽莎-断臂维纳斯-胜利女神-文艺复兴\n全程约3.5小时",
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    deep_travel_guide_id: abroad_guide_ids["皮埃尔·马丁"],
    title: "【法国历史】卢浮宫珍品故事【资深导游】",
    subtitle: "巴黎卢浮宫 资深导游",
    location: "境外精选",
    price: 198.00,
    sales_count: 156,
    description: "资深导游讲述卢浮宫历史和艺术珍品背后的精彩故事。",
    itinerary: "博物馆历史-艺术珍品-法国文化-宫廷历史\n全程约3小时",
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    deep_travel_guide_id: abroad_guide_ids["安娜·罗兰"],
    title: "【艺术教育】卢浮宫艺术鉴赏【通俗易懂】",
    subtitle: "巴黎卢浮宫 艺术学院讲师",
    location: "境外精选",
    price: 188.00,
    sales_count: 134,
    description: "艺术学院讲师深入浅出讲解，让艺术鉴赏变得通俗易懂。",
    itinerary: "艺术教育-绘画技法-艺术流派-美学鉴赏\n全程约3小时",
    featured: true,
    created_at: timestamp,
    updated_at: timestamp
  }
]

DeepTravelProduct.insert_all(abroad_products)

puts "✓ 深度旅行数据包加载完成"
