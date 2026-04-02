# frozen_string_literal: true

# cruises_v1 数据包
# 游轮游模块数据
#
# 用途：
# - 游轮公司、船只、航线数据
# - 游轮班次、舱房类型数据
# - 商家产品数据
#
# 加载方式：
# rake validator:reset_baseline

require_relative '../../../../../app/helpers/image_seed_helper'

puts "正在加载 cruises_v1 数据包..."

# ==================== 游轮公司数据 ====================

cruise_lines_data = [
  {
    name: '皇家加勒比国际游轮',
    name_en: 'Royal Caribbean International',
    logo_url: ImageSeedHelper.random_image_from_category(:cruise_logos),
    description: '全球豪华游轮领导品牌，拥有超量子系列、绿洲系列等多个创新船队',
    data_version: '0',
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    name: '地中海邮轮',
    name_en: 'MSC Cruises',
    logo_url: ImageSeedHelper.random_image_from_category(:cruise_logos),
    description: '欧洲第一、世界第四大邮轮公司，提供地中海特色服务',
    data_version: '0',
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    name: '爱达邮轮',
    name_en: 'AIDA Cruises',
    logo_url: ImageSeedHelper.random_image_from_category(:cruise_logos),
    description: '德国邮轮品牌，以年轻时尚的邮轮体验著称',
    data_version: '0',
    created_at: Time.current,
    updated_at: Time.current
  }
]

CruiseLine.insert_all(cruise_lines_data)

# 为新插入的 CruiseLine 生成 slug（FriendlyId 需要 save 触发回调）
puts "     正在为游轮公司生成 slug..."
CruiseLine.where(slug: [nil, '']).find_each(&:save)

# ==================== 游轮船只数据 ====================

# 获取游轮公司ID
royal_caribbean = CruiseLine.find_by(name: '皇家加勒比国际游轮')
msc_cruises = CruiseLine.find_by(name: '地中海邮轮')
aida_cruises = CruiseLine.find_by(name: '爱达邮轮')

cruise_ships_data = [
  {
    cruise_line_id: royal_caribbean.id,
    name: '海洋光谱号',
    name_en: 'Spectrum of the Seas',
    image_url: ImageSeedHelper.random_image_from_category(:cruise_ships),
    tonnage: 168666,
    passenger_capacity: 4246,
    features: ['超量子系列首艘邮轮', '甲板跳伞', '正宗川菜料理', '套房专享皇家府邸'],
    data_version: '0',
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_line_id: msc_cruises.id,
    name: '地中海辉煌号',
    name_en: 'MSC Bellissima',
    image_url: ImageSeedHelper.random_image_from_category(:cruise_ships),
    tonnage: 171598,
    passenger_capacity: 4500,
    features: ['米其林星级餐厅', '豪华购物长廊', '海上水上乐园'],
    data_version: '0',
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_line_id: msc_cruises.id,
    name: '地中海荣耀号',
    name_en: 'MSC Grandiosa',
    image_url: ImageSeedHelper.random_image_from_category(:cruise_ships),
    tonnage: 181000,
    passenger_capacity: 6334,
    features: ['欧洲最大邮轮之一', '室内娱乐长廊', '卡拉拉大理石装饰', 'MSC游艇俱乐部'],
    data_version: '0',
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_line_id: msc_cruises.id,
    name: '地中海传奇号',
    name_en: 'MSC Fantasia',
    image_url: ImageSeedHelper.random_image_from_category(:cruise_ships),
    tonnage: 137936,
    passenger_capacity: 3959,
    features: ['施华洛世奇水晶楼梯', '四维影院', '一级方程式赛车模拟器'],
    data_version: '0',
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_line_id: royal_caribbean.id,
    name: '海洋和悦号',
    name_en: 'Harmony of the Seas',
    image_url: ImageSeedHelper.random_image_from_category(:cruise_ships),
    tonnage: 226963,
    passenger_capacity: 6780,
    features: ['世界最大邮轮之一', '中央公园', '百老汇歌剧院', '终极深渊滑梯'],
    data_version: '0',
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_line_id: aida_cruises.id,
    name: '爱达新星号',
    name_en: 'AIDA Nova',
    image_url: ImageSeedHelper.random_image_from_category(:cruise_ships),
    tonnage: 183900,
    passenger_capacity: 5200,
    features: ['环保LNG动力', '全景观景台', '海上啤酒花园'],
    data_version: '0',
    created_at: Time.current,
    updated_at: Time.current
  }
]

CruiseShip.insert_all(cruise_ships_data)
# Regenerate slugs for FriendlyId (insert_all bypasses callbacks)
CruiseShip.find_each(&:save)

# ==================== 航线数据 ====================

cruise_routes_data = [
  { name: '日韩', region: 'japan_korea', icon_url: ImageSeedHelper.random_image_from_category(:cruise_destinations), data_version: '0', created_at: Time.current, updated_at: Time.current },
  { name: '三峡', region: 'yangtze_river', icon_url: ImageSeedHelper.random_image_from_category(:cruise_destinations), data_version: '0', created_at: Time.current, updated_at: Time.current },
  { name: '南北极', region: 'north_pole', icon_url: ImageSeedHelper.random_image_from_category(:cruise_destinations), data_version: '0', created_at: Time.current, updated_at: Time.current },
  { name: '东南亚', region: 'southeast_asia', icon_url: ImageSeedHelper.random_image_from_category(:cruise_destinations), data_version: '0', created_at: Time.current, updated_at: Time.current },
  { name: '地中海', region: 'mediterranean', icon_url: ImageSeedHelper.random_image_from_category(:cruise_destinations), data_version: '0', created_at: Time.current, updated_at: Time.current },
  { name: '阿拉斯加', region: 'alaska', icon_url: ImageSeedHelper.random_image_from_category(:cruise_destinations), data_version: '0', created_at: Time.current, updated_at: Time.current },
  { name: '欧洲河轮', region: 'europe_river', icon_url: ImageSeedHelper.random_image_from_category(:cruise_destinations), data_version: '0', created_at: Time.current, updated_at: Time.current },
  { name: '加勒比', region: 'caribbean', icon_url: ImageSeedHelper.random_image_from_category(:cruise_destinations), data_version: '0', created_at: Time.current, updated_at: Time.current },
  { name: '中东', region: 'middle_east', icon_url: ImageSeedHelper.random_image_from_category(:cruise_destinations), data_version: '0', created_at: Time.current, updated_at: Time.current },
  { name: '西沙群岛', region: 'xisha_islands', icon_url: ImageSeedHelper.random_image_from_category(:cruise_destinations), data_version: '0', created_at: Time.current, updated_at: Time.current }
]

CruiseRoute.insert_all(cruise_routes_data)

# ==================== 游轮班次数据 ====================

# 获取船只和航线ID
spectrum = CruiseShip.find_by(name: '海洋光谱号')
bellissima = CruiseShip.find_by(name: '地中海辉煌号')
grandiosa = CruiseShip.find_by(name: '地中海荣耀号')
fantasia = CruiseShip.find_by(name: '地中海传奇号')
harmony = CruiseShip.find_by(name: '海洋和悦号')
aida_nova = CruiseShip.find_by(name: '爱达新星号')
japan_korea_route = CruiseRoute.find_by(region: 'japan_korea')
mediterranean_route = CruiseRoute.find_by(region: 'mediterranean')
southeast_asia_route = CruiseRoute.find_by(region: 'southeast_asia')
caribbean_route = CruiseRoute.find_by(region: 'caribbean')
yangtze_river_route = CruiseRoute.find_by(region: 'yangtze_river')
north_pole_route = CruiseRoute.find_by(region: 'north_pole')
alaska_route = CruiseRoute.find_by(region: 'alaska')
europe_river_route = CruiseRoute.find_by(region: 'europe_river')
middle_east_route = CruiseRoute.find_by(region: 'middle_east')
xisha_islands_route = CruiseRoute.find_by(region: 'xisha_islands')

cruise_sailings_data = [
  # ==================== 动态日期设置 ====================
  # 游轮班次覆盖范围：Date.today - 1.day 至 Date.today + 65.days (共65天)
  # 配合frozen_time.rb时间冻结机制，65天范围足够覆盖所有验证器查询
  # 使用 Date.today 作为静态锚点（系统时间，timezone-unaware）
  # 注意：Date.current 可能比 Date.today 晚1天（时区差异）
  
  # 海洋光谱号 - 明天出发的上海日韩航线（为v158验证器准备）
  # 注意：使用 Date.today + 2.days 确保覆盖 Date.current + 1.day
  # 原因：Date.current 可能比 Date.today 晚1天（时区差异）
  {
    cruise_ship_id: spectrum.id,
    cruise_route_id: japan_korea_route.id,
    departure_date: Date.today + 2.days,  # Date.today+2 覆盖 Date.current+1
    return_date: Date.today + 8.days,     # 6天后返回
    duration_days: 6,
    duration_nights: 5,
    departure_port: '上海登船',
    arrival_port: '上海离船',
    status: 'on_sale',
    boarding_address: '上海吴淞口国际邮轮码头 上海市宝山区吴淞口宝杨路1号',
    boarding_deadline: '14:30',
    itinerary: [
      { day: 1, port: '上海', title: '登船', description: '上海吴淞口码头登船，开启6天5晚日韩之旅', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 2, port: '海上巡航', title: '海上巡航', description: '享受游轮上的各种设施和娱乐活动', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 3, port: '福冈', title: '岸上观光', description: '日本福冈博多港，购物天堂和美食之都', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 4, port: '济州岛', title: '岸上观光', description: '韩国济州岛，火山岛屿风光', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 5, port: '海上巡航', title: '海上巡航', description: '海上巡航日，放松休闲', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 6, port: '上海', title: '离船', description: '返回上海吴淞口码头，结束愉快的游轮之旅', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] }
    ],
    created_at: Time.current,
    updated_at: Time.current
  },
  # 海洋光谱号 - 日韩航线 (香港出发, 6天5晚, 最近班次)
  {
    cruise_ship_id: spectrum.id,
    cruise_route_id: japan_korea_route.id,
    departure_date: Date.today + 2.days,
    return_date: Date.today + 7.days,
    duration_days: 6,
    duration_nights: 5,
    departure_port: '香港登船',
    arrival_port: '香港离船',
    status: 'on_sale',
    boarding_address: '香港启德邮轮码头 香港九龙承丰道33号',
    boarding_deadline: '14:30',
    itinerary: [
      { 
        day: 1, 
        port: '香港', 
        title: '登船',
        description: "登船地点 香港启德邮轮码头 香港九龙承丰道33号\n\n登船截止时间 14:30\n\n行程描述 欢迎来到香港启德邮轮码头，开启您此次的游轮之旅。您可以到达港口后办理行李托运及登船手续，通过安检与海关后，便可凭房卡登船。祝您与您的家人共同享受这无与伦比的游轮假期！\n\n码头地址：香港启德邮轮码头 香港九龙承丰道33号",
        images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)]
      },
      { 
        day: 2, 
        port: '冲绳', 
        title: '岸上观光',
        description: "行程描述 今天我们将抵达日本冲绳那霸港。冲绳被誉为日本的夏威夷，拥有迷人的海滩、独特的琉球文化和美丽的水下世界。\n\n推荐活动 您可以参加岸上游览项目：首里城探访（琉球王国的宫殿遗址，世界文化遗产）、美丽海水族馆参观（世界级的水族馆，拥有巨大的黑潮之海水槽）、国际通商店街购物（冲绳最繁华的商业街，可以购买当地特产）。\n\n美食推荐 不要错过冲绳特色美食：冲绳荞麦面、塔可饭、海葡萄、苦瓜炒蛋、紫薯塔等。国际通沿街有许多餐厅和小吃店可以品尝。\n\n温馨提示 冲绳气候温暖，请携带防晒用品。岸上游览时间约为8小时，请在16:00前返回船上。",
        images: ImageSeedHelper.random_images_from_category(:cruise_destinations, count: 2)
      },
      { 
        day: 3, 
        port: '福冈', 
        title: '岸上观光',
        description: "行程描述 今天我们将停靠福冈博多港。福冈是日本九州地区最大的城市，以美食、购物和温泉而闻名。\n\n推荐活动 您可以前往太宰府天满宫参拜（日本著名的学问之神神社）、福冈塔观景（高234米，可俯瞰整个城市和博多湾）、栉田神社游览（福冈最古老的神社之一）、天神地下街购物（九州最大的地下商业街）。\n\n美食推荐 福冈拉面是必尝美食，尤其是博多豚骨拉面。一兰拉面、一风堂、博多だるま等都是知名店铺。此外还有明太子、牛杂锅、鸡肉水炊等当地特色。\n\n购物天堂 天神地区是福冈的购物中心，拥有三越、大丸、PARCO等百货商场。博多运河城是大型综合购物娱乐设施。\n\n温馨提示 岸上游览时间约为9小时，请在17:00前返回船上。",
        images: ImageSeedHelper.random_images_from_category(:cruise_destinations, count: 2)
      },
      { 
        day: 4, 
        port: '济州岛', 
        title: '岸上观光',
        description: "行程描述 今天我们将抵达韩国济州岛。济州岛是韩国最大的岛屿，以火山地貌、海岸风光和独特的海女文化而闻名。\n\n推荐活动 您可以参观城山日出峰（UNESCO世界自然遗产，壮观的火山口）、万丈窟（世界最长的熔岩洞之一）、泰迪熊博物馆、涉地可支海岸（热门韩剧拍摄地）。\n\n美食推荐 济州岛特色美食包括黑猪肉烤肉、鲍鱼粥、海鲜火锅、济州橘子等。您还可以品尝当地的马格利米酒。\n\n购物建议 济州岛有乐天免税店、新罗免税店等大型免税商场，可以购买化妆品、服装、韩国特产等。\n\n温馨提示 岸上游览时间约为8小时，请在17:00前返回船上。",
        images: ImageSeedHelper.random_images_from_category(:cruise_destinations, count: 2)
      },
      { 
        day: 5, 
        port: '海上巡航', 
        title: '海上巡航',
        description: "行程描述 今天是海上巡航日，您可以尽情享受游轮上的各种设施和娱乐活动。\n\n甲板活动 在露天甲板上享受日光浴，参加游泳池派对，或在热水按摩池中放松身心。14楼的北极星观景台将在上午10:00-12:00、下午15:00-17:00开放，登上距海平面90米的观景臂，360度俯瞰壮丽海景。\n\n娱乐表演 晚上20:00在皇家剧院将上演精彩的百老汇风格歌舞表演《音乐之声》。在270度观景厅，您还可以欣赏结合了科技与艺术的多媒体表演。\n\n特色体验 南极球模拟跳伞体验（需预约）、甲板跳伞、海上碰碰车、攀岩墙等刺激项目等您挑战。喜欢安静的游客可以前往图书馆阅读，或参加摄影、绘画等艺术工作坊。",
        images: ImageSeedHelper.random_images_from_category(:cruise_destinations, count: 2)
      },
      { 
        day: 6, 
        port: '香港', 
        title: '离船',
        description: "行程描述 今天早晨我们将返回香港启德邮轮码头，结束这次精彩的游轮之旅。\n\n离船安排 游轮预计早上07:00抵达，办理离船手续后您可以在08:00-10:00之间离船。请在昨晚将大件行李放在房间门口，我们会帮您送至码头。随身贵重物品请自行携带。\n\n结账事宜 如果您的房卡绑定了信用卡，所有船上消费将自动结算。如需查看账单明细，可在离船前一天到服务台索取。\n\n码头交通 码头交通便利，可选择地铁、巴士、出租车等多种交通方式前往市区。\n\n感谢致辞 感谢您选择海洋光谱号，期待再次为您服务！祝您旅途愉快！",
        images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)]
      }
    ],
    created_at: Time.current,
    updated_at: Time.current
  },
  # 海洋光谱号 - 日韩航线 (支持西时区用户的过去班次)
  {
    cruise_ship_id: spectrum.id,
    cruise_route_id: japan_korea_route.id,
    departure_date: Date.today - 1.day,
    return_date: Date.today + 4.days,
    duration_days: 6,
    duration_nights: 5,
    departure_port: '香港登船',
    arrival_port: '上海离船',
    status: 'on_sale',
    boarding_address: '香港启德邮轮码头 香港九龙承丰道33号',
    boarding_deadline: '14:30',
    itinerary: [
      { 
        day: 1, 
        port: '香港', 
        title: '登船',
        description: "登船地点 香港启德邮轮码头 香港九龙承丰道33号\n\n登船截止时间 14:30\n\n行程描述 欢迎来到香港启德邮轮码头，开启您此次的游轮之旅。您可以到达港口后办理行李托运及登船手续，通过安检与海关后，便可凭房卡登船。祝您与您的家人共同享受这无与伦比的游轮假期！\n\n码头地址：香港启德邮轮码头 香港九龙承丰道33号",
        images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)]
      },
      { 
        day: 2, 
        port: '海上巡航', 
        title: '岸上观光',
        description: "行程描述 从欧洲到美洲，从澳洲到北极，尝鲜之旅，远到想不到！尝遍世界之味，新开辟的川菜、茶餐厅、铁板烧、中式茶饮更为你带来远游后家的暖心；海上超大的自助餐厅静候每一位大胃美食家的光临。\n\n船上设施 海洋光谱号拥有丰富的娱乐设施，包括北极星观景台、南极球模拟跳伞体验、甲板跳伞、海上碰碰车、室内游泳池等。您还可以参加瑜伽课程、健身房锻炼，或在皇家剧院欣赏百老汇风格的演出。\n\n餐饮选择 主餐厅提供中西式自助早餐，午餐和晚餐可选择正式的点餐服务。特色餐厅包括日式铁板烧、川菜馆、意大利餐厅等。14楼的自助餐厅提供全天候美食，让您随时享用各国料理。",
        images: ImageSeedHelper.random_images_from_category(:cruise_destinations, count: 2)
      },
      { 
        day: 3, 
        port: '冲绳', 
        title: '岸上观光',
        description: "行程描述 今天我们将抵达日本冲绳那霸港。冲绳被誉为日本的夏威夷，拥有迷人的海滩、独特的琉球文化和美丽的水下世界。\n\n推荐活动 您可以参加岸上游览项目：首里城探访（琉球王国的宫殿遗址，世界文化遗产）、美丽海水族馆参观（世界级的水族馆，拥有巨大的黑潮之海水槽）、国际通商店街购物（冲绳最繁华的商业街，可以购买当地特产）。\n\n美食推荐 不要错过冲绳特色美食：冲绳荞麦面、塔可饭、海葡萄、苦瓜炒蛋、紫薯塔等。国际通沿街有许多餐厅和小吃店可以品尝。\n\n温馨提示 冲绳气候温暖，请携带防晒用品。岸上游览时间约为8小时，请在16:00前返回船上。",
        images: ImageSeedHelper.random_images_from_category(:cruise_destinations, count: 2)
      },
      { 
        day: 4, 
        port: '福冈', 
        title: '岸上观光',
        description: "行程描述 今天我们将停靠福冈博多港。福冈是日本九州地区最大的城市，以美食、购物和温泉而闻名。\n\n推荐活动 您可以前往太宰府天满宫参拜（日本著名的学问之神神社）、福冈塔观景（高234米，可俯瞰整个城市和博多湾）、栉田神社游览（福冈最古老的神社之一）、天神地下街购物（九州最大的地下商业街）。\n\n美食推荐 福冈拉面是必尝美食，尤其是博多豚骨拉面。一兰拉面、一风堂、博多だるま等都是知名店铺。此外还有明太子、牛杂锅、鸡肉水炊等当地特色。\n\n购物天堂 天神地区是福冈的购物中心，拥有三越、大丸、PARCO等百货商场。博多运河城是大型综合购物娱乐设施。\n\n温馨提示 岸上游览时间约为9小时，请在17:00前返回船上。",
        images: ImageSeedHelper.random_images_from_category(:cruise_destinations, count: 2)
      },
      { 
        day: 5, 
        port: '海上巡航', 
        title: '岸上观光',
        description: "行程描述 今天是海上巡航日，您可以尽情享受游轮上的各种设施和娱乐活动。\n\n甲板活动 在露天甲板上享受日光浴，参加游泳池派对，或在热水按摩池中放松身心。14楼的北极星观景台将在上午10:00-12:00、下午15:00-17:00开放，登上距海平面90米的观景臂，360度俯瞰壮丽海景。\n\n娱乐表演 晚上20:00在皇家剧院将上演精彩的百老汇风格歌舞表演《音乐之声》。在270度观景厅，您还可以欣赏结合了科技与艺术的多媒体表演。\n\n特色体验 南极球模拟跳伞体验（需预约）、甲板跳伞、海上碰碰车、攀岩墙等刺激项目等您挑战。喜欢安静的游客可以前往图书馆阅读，或参加摄影、绘画等艺术工作坊。\n\n餐饮活动 晚上将举行船长欢迎晚宴，这是一个正式的用餐场合，建议穿着正装出席。主餐厅将提供精致的多道式西餐。",
        images: ImageSeedHelper.random_images_from_category(:cruise_destinations, count: 2)
      },
      { 
        day: 6, 
        port: '上海', 
        title: '离船',
        description: "行程描述 今天早晨我们将抵达上海吴淞口国际邮轮码头，结束这次精彩的游轮之旅。\n\n离船安排 游轮预计早上07:00抵达，办理离船手续后您可以在08:00-10:00之间离船。请在昨晚将大件行李放在房间门口，我们会帮您送至码头。随身贵重物品请自行携带。\n\n结账事宜 如果您的房卡绑定了信用卡，所有船上消费将自动结算。如需查看账单明细，可在离船前一天到服务台索取。\n\n码头交通 码头有出租车、网约车上客点，也有地铁3号线宝杨路站（步行约15分钟）。如需前往市区，建议提前预约接送服务。\n\n感谢致辞 感谢您选择海洋光谱号，期待再次为您服务！祝您旅途愉快！",
        images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)]
      }
    ],
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_ship_id: spectrum.id,
    cruise_route_id: japan_korea_route.id,
    departure_date: Date.today + 12.days,
    return_date: Date.today + 16.days,
    duration_days: 5,
    duration_nights: 4,
    departure_port: '上海登船',
    arrival_port: '上海离船',
    status: 'on_sale',
    boarding_address: '上海吴淞口国际邮轮码头 上海市宝山区吴淞口宝杨路1号',
    boarding_deadline: '14:30',
    itinerary: [
      { 
        day: 1, 
        port: '上海', 
        title: '登船',
        description: "登船地点 上海吴淞口国际邮轮码头 上海市宝山区吴淞口宝杨路1号\n\n登船截止时间 14:30\n\n行程描述 欢迎来到上海宝山码头，开启您此次的游轮之旅。您可以到达港口后办理行李托运及登船手续，通过安检与海关后，便可凭房卡登船。祝您与您的家人共同享受这无与伦比的游轮假期！\n\n码头地址：上海吴淞口国际邮轮码头 上海市宝山区吴淞口宝杨路1号\n\n交通指南 地铁3号线宝杨路站下车步行约15分钟；驾车可导航至宝杨路1号，码头提供付费停车服务。",
        images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)]
      },
      { 
        day: 2, 
        port: '济州岛', 
        title: '岸上观光',
        description: "行程描述 今天我们将抵达韩国济州岛。济州岛是韩国最大的岛屿，被誉为韩国的夏威夷，以其独特的火山地貌、美丽的海岸线和丰富的自然景观而闻名。\n\n推荐活动 您可以参加岸上游览：城山日出峰登顶（世界自然遗产，火山口观景）、涉地可支海岸漫步（热门韩剧拍摄地）、泰迪熊博物馆参观（适合亲子游）、东门市场品尝美食（当地海鲜市场）。\n\n美食推荐 济州岛特色美食包括黑猪肉烤肉、鲍鱼粥、海鲜火锅、橘子巧克力等。东门市场和中央地下商街有许多小吃摊位。\n\n购物指南 新罗免税店、乐天免税店提供各类国际品牌商品。当地特产包括济州柑橘、绿茶制品、黑猪肉制品、海产品等。\n\n温馨提示 岸上游览时间约为8小时，请在17:00前返回船上。韩国使用韩元，建议提前兑换或使用信用卡。",
        images: ImageSeedHelper.random_images_from_category(:cruise_destinations, count: 2)
      },
      { 
        day: 3, 
        port: '釜山', 
        title: '岸上观光',
        description: "行程描述 今天我们将停靠韩国第二大城市釜山。釜山是韩国最重要的港口城市，拥有美丽的海滩、现代化的都市风光和丰富的历史文化。\n\n推荐活动 海云台海滩漫步（韩国最著名的海滩）、甘川文化村探访（彩色房子艺术村，摄影胜地）、札嘎其海鲜市场体验（韩国最大的海鲜市场）、龙头山公园观景（釜山塔360度观景）、西面购物区逛街。\n\n美食推荐 釜山以海鲜闻名，必尝美食包括生鱼片、海鲜煎饼、猪肉汤饭、血肠、炸鸡配啤酒等。札嘎其市场可以购买海鲜后现场加工。\n\n购物天堂 西面地下街、光复路时尚街、新世界百货、乐天百货等购物场所应有尽有。釜山的化妆品和服饰价格相对首尔更优惠。\n\n温馨提示 岸上游览时间约为9小时，请在18:00前返回船上。釜山地铁便利，建议购买交通卡使用。",
        images: ImageSeedHelper.random_images_from_category(:cruise_destinations, count: 2)
      },
      { 
        day: 4, 
        port: '海上巡航', 
        title: '岸上观光',
        description: "行程描述 今天是海上巡航日，让您从岸上游览的疲惫中恢复过来，尽情享受游轮生活。\n\n休闲放松 在Spa温泉中心享受专业的按摩和美容护理服务（需额外付费），或在室内游泳池畅游，热水按摩池泡汤。喜欢安静的游客可以在图书馆阅读，或在观景休息室品茶聊天。\n\n亲子活动 海上历奇青少年活动中心为3-17岁的孩子提供分年龄段的托管服务和趣味活动，家长可以安心享受二人世界。14楼的南极球和甲板跳伞是孩子们的最爱。\n\n美食体验 午餐建议尝试14楼帆船自助餐厅的亚洲美食专区，有港式点心、日本寿司、东南亚咖喱等。晚餐可预约特色收费餐厅，如奥利弗意大利餐厅、泉·日式料理等。\n\n晚间娱乐 音乐厅将在晚上举办现场音乐演奏会，270度观景厅有多媒体表演秀，皇家赌场（仅在公海开放）提供各类博彩娱乐。",
        images: ImageSeedHelper.random_images_from_category(:cruise_destinations, count: 2)
      },
      { 
        day: 5, 
        port: '上海', 
        title: '离船',
        description: "行程描述 今天早晨我们将返回上海吴淞口国际邮轮码头，结束这次愉快的韩国之旅。\n\n离船安排 游轮预计早上07:30抵达，08:30开始办理离船手续。请在昨晚22:00前将大件行李放在房间门口，贴上行李条。贵重物品、证件、药品请随身携带。\n\n早餐安排 离船当天早餐将在06:00-08:00在14楼帆船自助餐厅提供。如果您需要提早离船，可以选择打包早餐。\n\n结账提示 请在离船前到前台结清所有船上消费，或确认已绑定信用卡自动扣款。如有疑问请及时联系宾客服务台。\n\n后续交通 码头出口有出租车候客区、网约车上客点，也可以提前预约接送服务。前往市区约需40-60分钟（视路况而定）。\n\n再会致辞 感谢您选择海洋光谱号，期待下次再会！",
        images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)]
      }
    ],
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_ship_id: spectrum.id,
    cruise_route_id: japan_korea_route.id,
    departure_date: Date.today + 15.days,
    return_date: Date.today + 20.days,
    duration_days: 6,
    duration_nights: 5,
    departure_port: '上海登船',
    arrival_port: '上海离船',
    status: 'on_sale',
    boarding_address: '上海吴淞口国际邮轮码头 上海市宝山区吴淞口宝杨路1号',
    boarding_deadline: '14:30',
    itinerary: [
      { day: 1, port: '上海', title: '登船', description: "登船地点 上海吴淞口国际邮轮码头 上海市宝山区吴淞口宝杨路1号\n\n登船截止时间 14:30\n\n行程描述 欢迎来到上海宝山码头，开启您此次的游轮之旅。您可以到达港口后办理行李托运及登船手续，通过安检与海关后，便可凭房卡登船。祝您与您的家人共同享受这无与伦比的游轮假期！\n\n码头地址：上海吴淞口国际邮轮码头 上海市宝山区吴淞口宝杨路1号\n\n交通指南 地铁3号线宝杨路站下车步行约15分钟；驾车可导航至宝杨路1号，码头提供付费停车服务。", images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 2, port: '海上巡航', title: '岸上观光', description: "行程描述 今天是海上巡航日，您可以尽情体验游轮上的各种设施和活动。\n\n船上设施 海洋光谱号拥有丰富的娱乐设施，包括北极星观景台、南极球模拟跳伞、甲板跳伞、海上碰碰车、室内游泳池等。您还可以参加瑜伽课程、健身房锻炼，或在皇家剧院欣赏精彩演出。\n\n餐饮选择 主餐厅提供中西式自助早餐，午餐和晚餐可选择正式的点餐服务。特色餐厅包括日式铁板烧、川菜馆、意大利餐厅等。14楼的自助餐厅提供全天候美食。", images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 3, port: '福冈', title: '岸上观光', description: "行程描述 今天我们将停靠福冈博多港。福冈是日本九州地区最大的城市，以美食、购物和温泉而闻名。\n\n推荐活动 您可以前往太宰府天满宫参拜、福冈塔观景、栉田神社游览、天神地下街购物。\n\n美食推荐 福冈拉面是必尝美食，尤其是博多豚骨拉面。一兰拉面、一风堂等都是知名店铺。\n\n温馨提示 岸上游览时间约为9小时，请在17:00前返回船上。", images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 4, port: '长崎', title: '岸上观光', description: "行程描述 今天我们将抵达长崎港。长崎是日本九州西岸的重要港口城市，拥有丰富的历史文化遗产。\n\n推荐活动 和平公园参观、哥拉巴园游览、长崎新地中华街逛街、稻佐山缆车登顶、大浦天主堂参观。\n\n美食推荐 长崎什锦面、佐世保汉堡、蜂蜜蛋糕、角煮馒头等。\n\n温馨提示 岸上游览时间约为8小时，请在17:00前返回船上。", images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 5, port: '海上巡航', title: '岸上观光', description: "行程描述 今天是海上巡航日，让您从岸上游览中恢复精力，享受悠闲的海上时光。\n\n休闲放松 在Spa温泉中心享受专业按摩，或在热水按摩池中放松身心。\n\n美食体验 午餐可尝试14楼自助餐厅的亚洲美食专区。晚餐可预约特色收费餐厅。\n\n晚间娱乐 音乐厅将举办现场音乐会，270度观景厅有多媒体表演。", images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 6, port: '上海', title: '离船', description: "行程描述 今天早晨我们将返回上海吴淞口国际邮轮码头。\n\n离船安排 游轮预计早上07:00抵达，办理离船手续后您可以在08:00-10:00之间离船。请在昨晚将大件行李放在房间门口。\n\n感谢致辞 感谢您选择海洋光谱号，期待再次为您服务！", images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] }
    ],
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_ship_id: spectrum.id,
    cruise_route_id: japan_korea_route.id,
    departure_date: Date.today + 20.days,
    return_date: Date.today + 24.days,
    duration_days: 5,
    duration_nights: 4,
    departure_port: '香港登船',
    arrival_port: '香港离船',
    status: 'on_sale',
    boarding_address: '香港启德邮轮码头 香港九龙承丰道33号',
    boarding_deadline: '14:30',
    itinerary: [
      { 
        day: 1, 
        port: '香港', 
        title: '登船',
        description: "登船地点 香港启德邮轮码头 香港九龙承丰道33号\n\n登船截止时间 14:30\n\n行程描述 欢迎来到香港启德邮轮码头，开启您此次的游轮之旅。您可以到达港口后办理行李托运及登船手续，通过安检与海关后，便可凭房卡登船。祝您与您的家人共同享受这无与伦比的游轮假期！\n\n码头地址：香港启德邮轮码头 香港九龙承丰道33号\n\n交通指南 港铁九龙湾站转乘5R巴士；驾车可导航至承丰道33号，码头提供付费停车服务。", 
        images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] 
      },
      { 
        day: 2, 
        port: '海上巡航', 
        title: '海上巡航',
        description: "行程描述 今天是海上巡航日，您可以尽情享受游轮上的各种设施和娱乐活动。\n\n船上设施 海洋光谱号拥有丰富的娱乐设施，包括北极星观景台、南极球模拟跳伞体验、甲板跳伞、海上碰碰车、室内游泳池等。您还可以参加瑜伽课程、健身房锻炼，或在皇家剧院欣赏百老汇风格的演出。\n\n餐饮选择 主餐厅提供中西式自助早餐，午餐和晚餐可选择正式的点餐服务。特色餐厅包括日式铁板烧、川菜馆、意大利餐厅等。14楼的自助餐厅提供全天候美食，让您随时享用各国料理。\n\n娱乐活动 参加甲板派对、游泳池活动、健身课程，或在图书馆享受静谧时光。晚上可在270度观景厅欣赏多媒体表演秀。", 
        images: ImageSeedHelper.random_images_from_category(:cruise_destinations, count: 2) 
      },
      { 
        day: 3, 
        port: '冲绳', 
        title: '岸上观光',
        description: "行程描述 今天我们将抵达日本冲绳那霸港。冲绳被誉为日本的夏威夷，拥有迷人的海滩、独特的琉球文化和美丽的水下世界。\n\n推荐活动 您可以参加岸上游览项目：首里城探访（琉球王国的宫殿遗址，世界文化遗产）、美丽海水族馆参观（世界级的水族馆，拥有巨大的黑潮之海水槽）、国际通商店街购物（冲绳最繁华的商业街，可以购买当地特产）。\n\n美食推荐 不要错过冲绳特色美食：冲绳荞麦面、塔可饭、海葡萄、苦瓜炒蛋、紫薯塔等。国际通沿街有许多餐厅和小吃店可以品尝。\n\n温馨提示 冲绳气候温暖，请携带防晒用品。岸上游览时间约为8小时，请在16:00前返回船上。", 
        images: ImageSeedHelper.random_images_from_category(:cruise_destinations, count: 2) 
      },
      { 
        day: 4, 
        port: '海上巡航', 
        title: '海上巡航',
        description: "行程描述 今天是海上巡航日，让您从岸上游览的疲惫中恢复过来，尽情享受游轮生活。\n\n甲板活动 在露天甲板上享受日光浴，参加游泳池派对，或在热水按摩池中放松身心。14楼的北极星观景台将在上午10:00-12:00、下午15:00-17:00开放，登上距海平面90米的观景臂，360度俯瞰壮丽海景。\n\n休闲放松 在Spa温泉中心享受专业的按摩和美容护理服务（需额外付费），或在室内游泳池畅游，热水按摩池泡汤。喜欢安静的游客可以在图书馆阅读，或在观景休息室品茶聊天。\n\n晚间娱乐 晚上20:00在皇家剧院将上演精彩的百老汇风格歌舞表演。在270度观景厅，您还可以欣赏结合了科技与艺术的多媒体表演。", 
        images: ImageSeedHelper.random_images_from_category(:cruise_destinations, count: 2) 
      },
      { 
        day: 5, 
        port: '香港', 
        title: '离船',
        description: "行程描述 今天早晨我们将返回香港启德邮轮码头，结束这次精彩的游轮之旅。\n\n离船安排 游轮预计早上07:00抵达，办理离船手续后您可以在08:00-10:00之间离船。请在昨晚将大件行李放在房间门口，我们会帮您送至码头。随身贵重物品请自行携带。\n\n结账事宜 如果您的房卡绑定了信用卡，所有船上消费将自动结算。如需查看账单明细，可在离船前一天到服务台索取。\n\n码头交通 码头有出租车、网约车上客点，也可乘坐5R巴士前往港铁九龙湾站。如需前往市区，建议提前预约接送服务。\n\n感谢致辞 感谢您选择海洋光谱号，期待再次为您服务！祝您旅途愉快！", 
        images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] 
      }
    ],
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_ship_id: spectrum.id,
    cruise_route_id: japan_korea_route.id,
    departure_date: Date.today + 25.days,
    return_date: Date.today + 30.days,
    duration_days: 6,
    duration_nights: 5,
    departure_port: '上海登船',
    arrival_port: '上海离船',
    status: 'on_sale',
    boarding_address: '上海吴淞口国际邮轮码头 上海市宝山区吴淞口宝杨路1号',
    boarding_deadline: '14:30',
    itinerary: [
      { 
        day: 1, 
        port: '上海', 
        title: '登船',
        description: "登船地点 上海吴淞口国际邮轮码头 上海市宝山区吴淞口宝杨路1号\n\n登船截止时间 14:30\n\n行程描述 欢迎来到上海宝山码头，开启您此次的游轮之旅。您可以到达港口后办理行李托运及登船手续，通过安检与海关后，便可凭房卡登船。祝您与您的家人共同享受这无与伦比的游轮假期！\n\n码头地址：上海吴淞口国际邮轮码头 上海市宝山区吴淞口宝杨路1号\n\n交通指南 地铁3号线宝杨路站下车步行约15分钟；驾车可导航至宝杨路1号，码头提供付费停车服务。", 
        images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] 
      },
      { 
        day: 2, 
        port: '济州岛', 
        title: '岸上观光',
        description: "行程描述 今天我们将抵达韩国济州岛。济州岛是韩国最大的岛屿，被誉为韩国的夏威夷，以其独特的火山地貌、美丽的海岸线和丰富的自然景观而闻名。\n\n推荐活动 您可以参加岸上游览：城山日出峰登顶（世界自然遗产，火山口观景）、涉地可支海岸漫步（热门韩剧拍摄地）、泰迪熊博物馆参观（适合亲子游）、东门市场品尝美食（当地海鲜市场）。\n\n美食推荐 济州岛特色美食包括黑猪肉烤肉、鲍鱼粥、海鲜火锅、橘子巧克力等。东门市场和中央地下商街有许多小吃摊位。\n\n购物指南 新罗免税店、乐天免税店提供各类国际品牌商品。当地特产包括济州柑橘、绿茶制品、黑猪肉制品、海产品等。\n\n温馨提示 岸上游览时间约为8小时，请在17:00前返回船上。韩国使用韩元，建议提前兑换或使用信用卡。", 
        images: ImageSeedHelper.random_images_from_category(:cruise_destinations, count: 2) 
      },
      { 
        day: 3, 
        port: '釜山', 
        title: '岸上观光',
        description: "行程描述 今天我们将停靠韩国第二大城市釜山。釜山是韩国最重要的港口城市，拥有美丽的海滩、现代化的都市风光和丰富的历史文化。\n\n推荐活动 海云台海滩漫步（韩国最著名的海滩）、甘川文化村探访（彩色房子艺术村，摄影胜地）、札嘎其海鲜市场体验（韩国最大的海鲜市场）、龙头山公园观景（釜山塔360度观景）、西面购物区逛街。\n\n美食推荐 釜山以海鲜闻名，必尝美食包括生鱼片、海鲜煎饼、猪肉汤饭、血肠、炸鸡配啤酒等。札嘎其市场可以购买海鲜后现场加工。\n\n购物天堂 西面地下街、光复路时尚街、新世界百货、乐天百货等购物场所应有尽有。釜山的化妆品和服饰价格相对首尔更优惠。\n\n温馨提示 岸上游览时间约为9小时，请在18:00前返回船上。釜山地铁便利，建议购买交通卡使用。", 
        images: ImageSeedHelper.random_images_from_category(:cruise_destinations, count: 2) 
      },
      { 
        day: 4, 
        port: '福冈', 
        title: '岸上观光',
        description: "行程描述 今天我们将停靠福冈博多港。福冈是日本九州地区最大的城市，以美食、购物和温泉而闻名。\n\n推荐活动 您可以前往太宰府天满宫参拜（日本著名的学问之神神社）、福冈塔观景（高234米，可俯瞰整个城市和博多湾）、栉田神社游览（福冈最古老的神社之一）、天神地下街购物（九州最大的地下商业街）。\n\n美食推荐 福冈拉面是必尝美食，尤其是博多豚骨拉面。一兰拉面、一风堂、博多だるま等都是知名店铺。此外还有明太子、牛杂锅、鸡肉水炊等当地特色。\n\n购物天堂 天神地区是福冈的购物中心，拥有三越、大丸、PARCO等百货商场。博多运河城是大型综合购物娱乐设施。\n\n温馨提示 岸上游览时间约为9小时，请在17:00前返回船上。", 
        images: ImageSeedHelper.random_images_from_category(:cruise_destinations, count: 2) 
      },
      { 
        day: 5, 
        port: '海上巡航', 
        title: '海上巡航',
        description: "行程描述 今天是海上巡航日，让您从岸上游览中恢复精力，享受悠闲的海上时光。\n\n休闲放松 在Spa温泉中心享受专业按摩，或在热水按摩池中放松身心。喜欢安静的游客可以在图书馆阅读，或在观景休息室品茶聊天。\n\n亲子活动 海上历奇青少年活动中心为3-17岁的孩子提供分年龄段的托管服务和趣味活动，家长可以安心享受二人世界。14楼的南极球和甲板跳伞是孩子们的最爱。\n\n美食体验 午餐建议尝试14楼帆船自助餐厅的亚洲美食专区，有港式点心、日本寿司、东南亚咖喱等。晚餐可预约特色收费餐厅，如奥利弗意大利餐厅、泉·日式料理等。\n\n晚间娱乐 音乐厅将在晚上举办现场音乐演奏会，270度观景厅有多媒体表演秀，皇家赌场（仅在公海开放）提供各类博彩娱乐。", 
        images: ImageSeedHelper.random_images_from_category(:cruise_destinations, count: 2) 
      },
      { 
        day: 6, 
        port: '上海', 
        title: '离船',
        description: "行程描述 今天早晨我们将返回上海吴淞口国际邮轮码头，结束这次愉快的韩国日本之旅。\n\n离船安排 游轮预计早上07:30抵达，08:30开始办理离船手续。请在昨晚22:00前将大件行李放在房间门口，贴上行李条。贵重物品、证件、药品请随身携带。\n\n早餐安排 离船当天早餐将在06:00-08:00在14楼帆船自助餐厅提供。如果您需要提早离船，可以选择打包早餐。\n\n结账提示 请在离船前到前台结清所有船上消费，或确认已绑定信用卡自动扣款。如有疑问请及时联系宾客服务台。\n\n后续交通 码头出口有出租车候客区、网约车上客点，也可以提前预约接送服务。前往市区约需40-60分钟（视路况而定）。\n\n再会致辞 感谢您选择海洋光谱号，期待下次再会！", 
        images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] 
      }
    ],
    created_at: Time.current,
    updated_at: Time.current
  },
  # 地中海辉煌号 - 日韩航线
  {
    cruise_ship_id: bellissima.id,
    cruise_route_id: japan_korea_route.id,
    departure_date: Date.today + 18.days,
    return_date: Date.today + 25.days,
    duration_days: 8,
    duration_nights: 7,
    departure_port: '上海登船',
    arrival_port: '上海离船',
    status: 'on_sale',
    boarding_address: '上海吴淞口国际邮轮码头 上海市宝山区吴淞口宝杨路1号',
    boarding_deadline: '14:30',
    itinerary: [
      { day: 1, port: '上海', description: '下午登船' },
      { day: 2, port: '长崎', description: '日本历史名城' },
      { day: 3, port: '福冈', description: '购物天堂' },
      { day: 4, port: '海上巡航', description: '享受船上设施' },
      { day: 5, port: '冲绳', description: '热带风情' },
      { day: 6, port: '海上巡航', description: '甲板活动' },
      { day: 7, port: '海上巡航', description: '晚宴之夜' },
      { day: 8, port: '上海', description: '早晨抵达' }
    ],
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_ship_id: bellissima.id,
    cruise_route_id: japan_korea_route.id,
    departure_date: Date.today + 22.days,
    return_date: Date.today + 28.days,
    duration_days: 7,
    duration_nights: 6,
    departure_port: '香港登船',
    arrival_port: '香港离船',
    status: 'on_sale',
    boarding_address: '香港启德邮轮码头 香港九龙承丰道33号',
    boarding_deadline: '14:30',
    itinerary: [
      { day: 1, port: '香港', description: '下午登船' },
      { day: 2, port: '海上巡航', description: '享受船上设施' },
      { day: 3, port: '冲绳', description: '热带风情' },
      { day: 4, port: '福冈', description: '购物天堂' },
      { day: 5, port: '济州岛', description: '探索韩国文化' },
      { day: 6, port: '海上巡航', description: '甲板活动' },
      { day: 7, port: '香港', description: '早晨抵达' }
    ],
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_ship_id: bellissima.id,
    cruise_route_id: japan_korea_route.id,
    departure_date: Date.today + 30.days,
    return_date: Date.today + 35.days,
    duration_days: 6,
    duration_nights: 5,
    departure_port: '上海登船',
    arrival_port: '上海离船',
    status: 'on_sale',
    boarding_address: '上海吴淞口国际邮轮码头 上海市宝山区吴淞口宝杨路1号',
    boarding_deadline: '14:30',
    itinerary: [
      { day: 1, port: '上海', description: '下午登船' },
      { day: 2, port: '济州岛', description: '探索韩国文化' },
      { day: 3, port: '釜山', description: '海云台海滩' },
      { day: 4, port: '海上巡航', description: '享受船上设施' },
      { day: 5, port: '海上巡航', description: '甲板活动' },
      { day: 6, port: '上海', description: '早晨抵达' }
    ],
    created_at: Time.current,
    updated_at: Time.current
  },
  # 爱达新星号 - 东南亚航线
  # v116需要：9天8晚，上海出发
  {
    cruise_ship_id: aida_nova.id,
    cruise_route_id: southeast_asia_route.id,
    departure_date: Date.today + 2.days,
    return_date: Date.today + 10.days,
    duration_days: 9,
    duration_nights: 8,
    departure_port: '上海登船',
    arrival_port: '上海离船',
    status: 'on_sale',
    boarding_address: '上海吴淞口国际邮轮码头 上海市宝山区吴淞口宝杨路1号',
    boarding_deadline: '14:30',
    itinerary: [
      { day: 1, port: '上海', description: '下午登船，晚上启航' },
      { day: 2, port: '海上巡航', description: '享受船上设施' },
      { day: 3, port: '海上巡航', description: '甲板活动' },
      { day: 4, port: '岘港', description: '越南海滨城市' },
      { day: 5, port: '芽庄', description: '海岛风光' },
      { day: 6, port: '新加坡', description: '狮城一日游' },
      { day: 7, port: '海上巡航', description: '船上娱乐' },
      { day: 8, port: '海上巡航', description: '晚宴之夜' },
      { day: 9, port: '上海', description: '早晨抵达' }
    ],
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_ship_id: aida_nova.id,
    cruise_route_id: southeast_asia_route.id,
    departure_date: Date.today + 5.days,
    return_date: Date.today + 13.days,
    duration_days: 9,
    duration_nights: 8,
    departure_port: '上海登船',
    arrival_port: '上海离船',
    status: 'on_sale',
    boarding_address: '上海吴淞口国际邮轮码头 上海市宝山区吴淞口宝杨路1号',
    boarding_deadline: '14:30',
    itinerary: [
      { day: 1, port: '上海', description: '下午登船，晚上启航' },
      { day: 2, port: '海上巡航', description: '享受船上设施' },
      { day: 3, port: '海上巡航', description: '甲板活动' },
      { day: 4, port: '岘港', description: '越南海滨城市' },
      { day: 5, port: '芽庄', description: '海岛风光' },
      { day: 6, port: '新加坡', description: '狮城一日游' },
      { day: 7, port: '海上巡航', description: '船上娱乐' },
      { day: 8, port: '海上巡航', description: '晚宴之夜' },
      { day: 9, port: '上海', description: '早晨抵达' }
    ],
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_ship_id: aida_nova.id,
    cruise_route_id: southeast_asia_route.id,
    departure_date: Date.today + 8.days,
    return_date: Date.today + 16.days,
    duration_days: 9,
    duration_nights: 8,
    departure_port: '上海登船',
    arrival_port: '上海离船',
    status: 'on_sale',
    boarding_address: '上海吴淞口国际邮轮码头 上海市宝山区吴淞口宝杨路1号',
    boarding_deadline: '14:30',
    itinerary: [
      { day: 1, port: '上海', description: '下午登船，晚上启航' },
      { day: 2, port: '海上巡航', description: '享受船上设施' },
      { day: 3, port: '海上巡航', description: '甲板活动' },
      { day: 4, port: '岘港', description: '越南海滨城市' },
      { day: 5, port: '芽庄', description: '海岛风光' },
      { day: 6, port: '新加坡', description: '狮城一日游' },
      { day: 7, port: '海上巡航', description: '船上娱乐' },
      { day: 8, port: '海上巡航', description: '晚宴之夜' },
      { day: 9, port: '上海', description: '早晨抵达' }
    ],
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_ship_id: aida_nova.id,
    cruise_route_id: southeast_asia_route.id,
    departure_date: Date.today + 3.days,
    return_date: Date.today + 10.days,
    duration_days: 8,
    duration_nights: 7,
    departure_port: '上海登船',
    arrival_port: '上海离船',
    status: 'on_sale',
    boarding_address: '上海吴淞口国际邮轮码头 上海市宝山区吴淞口宝杨路1号',
    boarding_deadline: '14:30',
    itinerary: [
      { day: 1, port: '上海', description: '下午登船，晚上启航' },
      { day: 2, port: '海上巡航', description: '享受船上设施' },
      { day: 3, port: '海上巡航', description: '甲板活动' },
      { day: 4, port: '岘港', description: '越南海滨城市' },
      { day: 5, port: '芽庄', description: '海岛风光' },
      { day: 6, port: '海上巡航', description: '船上娱乐' },
      { day: 7, port: '海上巡航', description: '晚宴之夜' },
      { day: 8, port: '上海', description: '早晨抵达' }
    ],
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_ship_id: aida_nova.id,
    cruise_route_id: southeast_asia_route.id,
    departure_date: Date.today + 6.days,
    return_date: Date.today + 12.days,
    duration_days: 7,
    duration_nights: 6,
    departure_port: '香港登船',
    arrival_port: '香港离船',
    status: 'on_sale',
    boarding_address: '香港启德邮轮码头 香港九龙承丰道33号',
    boarding_deadline: '14:30',
    itinerary: [
      { day: 1, port: '香港', description: '下午登船，晚上启航' },
      { day: 2, port: '海上巡航', description: '享受船上设施' },
      { day: 3, port: '岘港', description: '越南海滨城市' },
      { day: 4, port: '芽庄', description: '海岛风光' },
      { day: 5, port: '海上巡航', description: '甲板活动' },
      { day: 6, port: '海上巡航', description: '船上娱乐' },
      { day: 7, port: '香港', description: '早晨抵达' }
    ],
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_ship_id: aida_nova.id,
    cruise_route_id: southeast_asia_route.id,
    departure_date: Date.today + 9.days,
    return_date: Date.today + 15.days,
    duration_days: 7,
    duration_nights: 6,
    departure_port: '香港登船',
    arrival_port: '香港离船',
    status: 'on_sale',
    boarding_address: '香港启德邮轮码头 香港九龙承丰道33号',
    boarding_deadline: '14:30',
    itinerary: [
      { day: 1, port: '香港', description: '下午登船，晚上启航' },
      { day: 2, port: '海上巡航', description: '享受船上设施' },
      { day: 3, port: '海防', description: '越南北部港口城市' },
      { day: 4, port: '岘港', description: '越南海滨城市' },
      { day: 5, port: '海上巡航', description: '甲板活动' },
      { day: 6, port: '海上巡航', description: '船上娱乐' },
      { day: 7, port: '香港', description: '早晨抵达' }
    ],
    created_at: Time.current,
    updated_at: Time.current
  },
  # 地中海辉煌号 - 日韩航线
  # v117需要：7天6晚，香港出发
  {
    cruise_ship_id: bellissima.id,
    cruise_route_id: japan_korea_route.id,
    departure_date: Date.today + 1.day,
    return_date: Date.today + 7.days,
    duration_days: 7,
    duration_nights: 6,
    departure_port: '香港登船',
    arrival_port: '香港离船',
    status: 'on_sale',
    boarding_address: '香港启德邮轮码头 香港九龙承丰道33号',
    boarding_deadline: '14:30',
    itinerary: [
      { day: 1, port: '香港', description: '下午登船，晚上启航' },
      { day: 2, port: '海上巡航', description: '享受船上设施' },
      { day: 3, port: '冲绳', description: '热带风情' },
      { day: 4, port: '福冈', description: '购物天堂' },
      { day: 5, port: '济州岛', description: '探索韩国文化' },
      { day: 6, port: '海上巡航', description: '甲板活动' },
      { day: 7, port: '香港', description: '早晨抵达' }
    ],
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_ship_id: bellissima.id,
    cruise_route_id: japan_korea_route.id,
    departure_date: Date.today + 4.days,
    return_date: Date.today + 10.days,
    duration_days: 7,
    duration_nights: 6,
    departure_port: '香港登船',
    arrival_port: '香港离船',
    status: 'on_sale',
    boarding_address: '香港启德邮轮码头 香港九龙承丰道33号',
    boarding_deadline: '14:30',
    itinerary: [
      { day: 1, port: '香港', description: '下午登船，晚上启航' },
      { day: 2, port: '海上巡航', description: '享受船上设施' },
      { day: 3, port: '福冈', description: '日本九州' },
      { day: 4, port: '鹿儿岛', description: '樱岛火山' },
      { day: 5, port: '济州', description: '韩国济州岛' },
      { day: 6, port: '海上巡航', description: '船上娱乐' },
      { day: 7, port: '香港', description: '早晨抵达' }
    ],
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_ship_id: bellissima.id,
    cruise_route_id: japan_korea_route.id,
    departure_date: Date.today + 7.days,
    return_date: Date.today + 13.days,
    duration_days: 7,
    duration_nights: 6,
    departure_port: '香港登船',
    arrival_port: '香港离船',
    status: 'on_sale',
    boarding_address: '香港启德邮轮码头 香港九龙承丰道33号',
    boarding_deadline: '14:30',
    itinerary: [
      { day: 1, port: '香港', description: '下午登船，晚上启航' },
      { day: 2, port: '海上巡航', description: '享受船上设施' },
      { day: 3, port: '福冈', description: '日本九州' },
      { day: 4, port: '鹿儿岛', description: '樱岛火山' },
      { day: 5, port: '济州', description: '韩国济州岛' },
      { day: 6, port: '海上巡航', description: '船上娱乐' },
      { day: 7, port: '香港', description: '早晨抵达' }
    ],
    created_at: Time.current,
    updated_at: Time.current
  },
  # 地中海辉煌号 - 地中海航线
  {
    cruise_ship_id: bellissima.id,
    cruise_route_id: mediterranean_route.id,
    departure_date: Date.today + 35.days,
    return_date: Date.today + 41.days,
    duration_days: 7,
    duration_nights: 6,
    departure_port: '巴塞罗那登船',
    arrival_port: '巴塞罗那离船',
    status: 'on_sale',
    boarding_address: '巴塞罗那港口码头 Port de Barcelona',
    boarding_deadline: '15:00',
    itinerary: [
      { day: 1, port: '巴塞罗那', title: '登船', description: '巴塞罗那港口码头登船，探索高迪建筑之都' },
      { day: 2, port: '马赛', title: '岸上观光', description: '法国马赛，普罗旺斯风情' },
      { day: 3, port: '热那亚', title: '岸上观光', description: '意大利热那亚，哥伦布故乡' },
      { day: 4, port: '罗马（奇维塔韦基亚）', title: '岸上观光', description: '永恒之城罗马，梵蒂冈朝圣' },
      { day: 5, port: '那不勒斯', title: '岸上观光', description: '那不勒斯湾，庞贝古城遗址' },
      { day: 6, port: '海上巡航', title: '海上巡航', description: '享受船上设施，地中海风情' },
      { day: 7, port: '巴塞罗那', title: '离船', description: '返回巴塞罗那，结束地中海之旅' }
    ],
    created_at: Time.current,
    updated_at: Time.current
  },
  # 地中海荣耀号 - 地中海航线
  {
    cruise_ship_id: grandiosa.id,
    cruise_route_id: mediterranean_route.id,
    departure_date: Date.today + 40.days,
    return_date: Date.today + 46.days,
    duration_days: 7,
    duration_nights: 6,
    departure_port: '巴塞罗那登船',
    arrival_port: '巴塞罗那离船',
    status: 'on_sale',
    boarding_address: 'Port de Barcelona Terminal MSC',
    boarding_deadline: '14:30',
    itinerary: [
      { day: 1, port: '巴塞罗那', title: '登船', description: '欧洲最大邮轮之旅开启' },
      { day: 2, port: '马赛', title: '岸上观光', description: '普罗旺斯门户马赛' },
      { day: 3, port: '热那亚', title: '岸上观光', description: '利古里亚海岸风情' },
      { day: 4, port: '那不勒斯', title: '岸上观光', description: '比萨之乡，庞贝古城' },
      { day: 5, port: '罗马（奇维塔韦基亚）', title: '岸上观光', description: '永恒之城罗马' },
      { day: 6, port: '海上巡航', title: '海上巡航', description: 'MSC游艇俱乐部体验' },
      { day: 7, port: '巴塞罗那', title: '离船', description: '返回巴塞罗那' }
    ],
    created_at: Time.current,
    updated_at: Time.current
  },
  # 地中海传奇号 - 地中海航线
  {
    cruise_ship_id: fantasia.id,
    cruise_route_id: mediterranean_route.id,
    departure_date: Date.today + 45.days,
    return_date: Date.today + 51.days,
    duration_days: 7,
    duration_nights: 6,
    departure_port: '巴塞罗那登船',
    arrival_port: '巴塞罗那离船',
    status: 'on_sale',
    boarding_address: 'Port de Barcelona',
    boarding_deadline: '14:00',
    itinerary: [
      { day: 1, port: '巴塞罗那', title: '登船', description: '施华洛世奇水晶邮轮' },
      { day: 2, port: '戛纳', title: '岸上观光', description: '法国电影节之城' },
      { day: 3, port: '热那亚', title: '岸上观光', description: '哥伦布故乡' },
      { day: 4, port: '那不勒斯', title: '岸上观光', description: '阿马尔菲海岸' },
      { day: 5, port: '罗马（奇维塔韦基亚）', title: '岸上观光', description: '古罗马遗迹' },
      { day: 6, port: '海上巡航', title: '海上巡航', description: 'F1模拟器体验' },
      { day: 7, port: '巴塞罗那', title: '离船', description: '返回巴塞罗那' }
    ],
    created_at: Time.current,
    updated_at: Time.current
  },
  # 海洋和悦号 - 地中海航线
  {
    cruise_ship_id: harmony.id,
    cruise_route_id: mediterranean_route.id,
    departure_date: Date.today + 50.days,
    return_date: Date.today + 56.days,
    duration_days: 7,
    duration_nights: 6,
    departure_port: '巴塞罗那登船',
    arrival_port: '巴塞罗那离船',
    status: 'on_sale',
    boarding_address: 'Port de Barcelona Royal Caribbean Terminal',
    boarding_deadline: '14:00',
    itinerary: [
      { day: 1, port: '巴塞罗那', title: '登船', description: '世界最大邮轮之旅' },
      { day: 2, port: '帕尔马', title: '岸上观光', description: '马略卡岛度假' },
      { day: 3, port: '马赛', title: '岸上观光', description: '蔚蓝海岸风情' },
      { day: 4, port: '佛罗伦萨（里窝那）', title: '岸上观光', description: '文艺复兴之都' },
      { day: 5, port: '罗马（奇维塔韦基亚）', title: '岸上观光', description: '永恒之城' },
      { day: 6, port: '海上巡航', title: '海上巡航', description: '中央公园漫步' },
      { day: 7, port: '巴塞罗那', title: '离船', description: '返回巴塞罗那' }
    ],
    created_at: Time.current,
    updated_at: Time.current
  },
  # 海洋光谱号 - 加勒比航线
  {
    cruise_ship_id: spectrum.id,
    cruise_route_id: caribbean_route&.id,
    departure_date: Date.today + 42.days,
    return_date: Date.today + 51.days,
    duration_days: 10,
    duration_nights: 9,
    departure_port: '迈阿密登船',
    arrival_port: '迈阿密离船',
    status: 'on_sale',
    boarding_address: 'PortMiami, Miami, FL 33132',
    boarding_deadline: '14:00',
    itinerary: [
      { day: 1, port: '迈阿密', title: '登船', description: '迈阿密港登船，阳光之城启航' },
      { day: 2, port: '海上巡航', title: '海上巡航', description: '享受船上设施，加勒比海巡航' },
      { day: 3, port: '大开曼岛', title: '岸上观光', description: '七英里海滩，浮潜天堂' },
      { day: 4, port: '牙买加（蒙特哥贝）', title: '岸上观光', description: '雷鬼音乐发源地，热带雨林探险' },
      { day: 5, port: '海地（拉巴第）', title: '岸上观光', description: '私人海滩，加勒比风情' },
      { day: 6, port: '圣托马斯', title: '岸上观光', description: '免税购物天堂，美属维尔京群岛' },
      { day: 7, port: '巴哈马（拿骚）', title: '岸上观光', description: '天堂岛，亚特兰蒂斯度假村' },
      { day: 8, port: '海上巡航', title: '海上巡航', description: '甲板派对，加勒比落日' },
      { day: 9, port: '海上巡航', title: '海上巡航', description: '船长晚宴，告别之夜' },
      { day: 10, port: '迈阿密', title: '离船', description: '返回迈阿密，结束加勒比之旅' }
    ],
    created_at: Time.current,
    updated_at: Time.current
  },

  # 地中海辉煌号 - 三峡航线（第1个航班）
  {
    cruise_ship_id: bellissima.id,
    cruise_route_id: yangtze_river_route&.id,
    departure_date: Date.today + 32.days,
    return_date: Date.today + 36.days,
    duration_days: 5,
    duration_nights: 4,
    departure_port: '重庆登船',
    arrival_port: '宜昌离船',
    status: 'on_sale',
    boarding_address: '重庆朝天门邮轮码头',
    boarding_deadline: '18:00',
    itinerary: [
      { day: 1, port: '重庆', title: '登船', description: '重庆朝天门码头登船，晚上启航，欣赏山城夜景。三峡邮轮为内河邮轮，航行平稳舒适', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 2, port: '丰都鬼城', title: '岸上观光', description: '游览丰都鬼城道教文化景区，下午途经忠县石宝寨古建筑', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 3, port: '白帝城/小三峡', title: '岸上观光', description: '参观白帝城，换乘小船游览小三峡自然风光。晚上穿行瞿塘峡、巫峡', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 4, port: '三峡大坝/西陵峡', title: '岸上观光', description: '参观三峡大坝水利工程，体验过五级船闸，航行西陵峡', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 5, port: '宜昌', title: '离船', description: '早晨抵达宜昌码头，结束长江三峡之旅', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] }
    ],
    created_at: Time.current,
    updated_at: Time.current
  },
  # 地中海辉煌号 - 三峡航线（第2个航班）
  {
    cruise_ship_id: bellissima.id,
    cruise_route_id: yangtze_river_route&.id,
    departure_date: Date.today + 37.days,
    return_date: Date.today + 41.days,
    duration_days: 5,
    duration_nights: 4,
    departure_port: '重庆登船',
    arrival_port: '宜昌离船',
    status: 'on_sale',
    boarding_address: '重庆朝天门邮轮码头',
    boarding_deadline: '18:00',
    itinerary: [
      { day: 1, port: '重庆', title: '登船', description: '重庆朝天门码头登船，晚上启航', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 2, port: '丰都鬼城', title: '岸上观光', description: '游览丰都鬼城，下午途经石宝寨', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 3, port: '白帝城/小三峡', title: '岸上观光', description: '参观白帝城，游览小三峡', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 4, port: '三峡大坝/西陵峡', title: '岸上观光', description: '参观三峡大坝，体验过船闸', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 5, port: '宜昌', title: '离船', description: '抵达宜昌，结束三峡之旅', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] }
    ],
    created_at: Time.current,
    updated_at: Time.current
  },
  # 地中海荣耀号 - 三峡航线
  {
    cruise_ship_id: grandiosa.id,
    cruise_route_id: yangtze_river_route&.id,
    departure_date: Date.today + 34.days,
    return_date: Date.today + 38.days,
    duration_days: 5,
    duration_nights: 4,
    departure_port: '重庆登船',
    arrival_port: '宜昌离船',
    status: 'on_sale',
    boarding_address: '重庆朝天门邮轮码头',
    boarding_deadline: '18:00',
    itinerary: [
      { day: 1, port: '重庆', title: '登船', description: '重庆登船，晚上启航', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 2, port: '丰都鬼城', title: '岸上观光', description: '游览丰都鬼城', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 3, port: '白帝城/小三峡', title: '岸上观光', description: '白帝城和小三峡游览', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 4, port: '三峡大坝/西陵峡', title: '岸上观光', description: '三峡大坝参观', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 5, port: '宜昌', title: '离船', description: '抵达宜昌', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] }
    ],
    created_at: Time.current,
    updated_at: Time.current
  },
  # 地中海传奇号 - 三峡航线
  {
    cruise_ship_id: fantasia.id,
    cruise_route_id: yangtze_river_route&.id,
    departure_date: Date.today + 44.days,
    return_date: Date.today + 48.days,
    duration_days: 5,
    duration_nights: 4,
    departure_port: '重庆登船',
    arrival_port: '宜昌离船',
    status: 'on_sale',
    boarding_address: '重庆朝天门邮轮码头',
    boarding_deadline: '18:00',
    itinerary: [
      { day: 1, port: '重庆', title: '登船', description: '重庆登船，晚上启航', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 2, port: '丰都鬼城', title: '岸上观光', description: '游览丰都鬼城', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 3, port: '白帝城/小三峡', title: '岸上观光', description: '白帝城和小三峡游览', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 4, port: '三峡大坝/西陵峡', title: '岸上观光', description: '三峡大坝参观', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 5, port: '宜昌', title: '离船', description: '抵达宜昌', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] }
    ],
    created_at: Time.current,
    updated_at: Time.current
  },
  # 爱达新星号 - 三峡航线（第1个航班）
  {
    cruise_ship_id: aida_nova.id,
    cruise_route_id: yangtze_river_route&.id,
    departure_date: Date.today + 38.days,
    return_date: Date.today + 42.days,
    duration_days: 5,
    duration_nights: 4,
    departure_port: '重庆登船',
    arrival_port: '宜昌离船',
    status: 'on_sale',
    boarding_address: '重庆朝天门邮轮码头',
    boarding_deadline: '18:00',
    itinerary: [
      { day: 1, port: '重庆', title: '登船', description: '重庆登船，晚上启航', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 2, port: '丰都鬼城', title: '岸上观光', description: '游览丰都鬼城', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 3, port: '白帝城/小三峡', title: '岸上观光', description: '白帝城和小三峡', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 4, port: '三峡大坝/西陵峡', title: '岸上观光', description: '三峡大坝参观', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 5, port: '宜昌', title: '离船', description: '抵达宜昌', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] }
    ],
    created_at: Time.current,
    updated_at: Time.current
  },
  # 爱达新星号 - 三峡航线（第2个航班）
  {
    cruise_ship_id: aida_nova.id,
    cruise_route_id: yangtze_river_route&.id,
    departure_date: Date.today + 48.days,
    return_date: Date.today + 52.days,
    duration_days: 5,
    duration_nights: 4,
    departure_port: '重庆登船',
    arrival_port: '宜昌离船',
    status: 'on_sale',
    boarding_address: '重庆朝天门邮轮码头',
    boarding_deadline: '18:00',
    itinerary: [
      { day: 1, port: '重庆', title: '登船', description: '重庆登船，晚上启航', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 2, port: '丰都鬼城', title: '岸上观光', description: '游览丰都鬼城', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 3, port: '白帝城/小三峡', title: '岸上观光', description: '白帝城和小三峡', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 4, port: '三峡大坝/西陵峡', title: '岸上观光', description: '三峡大坝参观', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 5, port: '宜昌', title: '离船', description: '抵达宜昌', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] }
    ],
    created_at: Time.current,
    updated_at: Time.current
  },
  # 海洋和悦号 - 阿拉斯加航线（第1个航班）
  {
    cruise_ship_id: harmony.id,
    cruise_route_id: alaska_route&.id,
    departure_date: Date.today + 46.days,
    return_date: Date.today + 53.days,
    duration_days: 8,
    duration_nights: 7,
    departure_port: '西雅图登船',
    arrival_port: '西雅图离船',
    status: 'on_sale',
    boarding_address: '西雅图港口邮轮码头',
    boarding_deadline: '15:00',
    itinerary: [
      { day: 1, port: '西雅图', title: '登船', description: '西雅图登船，开启阿拉斯加冰川探险之旅', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 2, port: '海上巡航', title: '海上巡航', description: '沿内湾航道北上，欣赏太平洋西北地区美景', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 3, port: '朱诺', title: '岸上观光', description: '阿拉斯加首府，参观门登霍尔冰川、淘金历史博物馆', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 4, port: '史凯威', title: '岸上观光', description: '淘金小镇，乘坐白色山口铁路，体验克朗代克淘金热历史', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 5, port: '冰河湾国家公园', title: '岸上观光', description: '近距离观赏壮观的潮汐冰川，观看冰川崩解奇观', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 6, port: '凯奇坎', title: '岸上观光', description: '阿拉斯加的三文鱼之都，参观图腾遗址公园', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 7, port: '海上巡航', title: '海上巡航', description: '返航途中尽享游轮设施', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 8, port: '西雅图', title: '离船', description: '抵达西雅图，结束冰川之旅', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] }
    ],
    created_at: Time.current,
    updated_at: Time.current
  },
  # 海洋和悦号 - 阿拉斯加航线（第2个航班）
  {
    cruise_ship_id: harmony.id,
    cruise_route_id: alaska_route&.id,
    departure_date: Date.today + 49.days,
    return_date: Date.today + 56.days,
    duration_days: 8,
    duration_nights: 7,
    departure_port: '温哥华登船',
    arrival_port: '温哥华离船',
    status: 'on_sale',
    boarding_address: '温哥华加拿大广场邮轮码头',
    boarding_deadline: '15:00',
    itinerary: [
      { day: 1, port: '温哥华', title: '登船', description: '温哥华登船，开启阿拉斯加冰川探险之旅', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 2, port: '海上巡航', title: '海上巡航', description: '沿内湾航道北上，欣赏加拿大BC省海岸风光', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 3, port: '凯奇坎', title: '岸上观光', description: '阿拉斯加的三文鱼之都，参观图腾遗址公园', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 4, port: '朱诺', title: '岸上观光', description: '阿拉斯加首府，参观门登霍尔冰川、淘金历史博物馆', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 5, port: '史凯威', title: '岸上观光', description: '淘金小镇，乘坐白色山口铁路，体验克朗代克淘金热历史', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 6, port: '维多利亚', title: '岸上观光', description: '英属哥伦比亚省省会，参观布查特花园、省议会大厦', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 7, port: '海上巡航', title: '海上巡航', description: '返航途中尽享游轮设施', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 8, port: '温哥华', title: '离船', description: '抵达温哥华，结束冰川之旅', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] }
    ],
    created_at: Time.current,
    updated_at: Time.current
  },
  # 海洋和悦号 - 阿拉斯加航线（第3个航班）
  {
    cruise_ship_id: harmony.id,
    cruise_route_id: alaska_route&.id,
    departure_date: Date.today + 55.days,
    return_date: Date.today + 62.days,
    duration_days: 8,
    duration_nights: 7,
    departure_port: '西雅图登船',
    arrival_port: '西雅图离船',
    status: 'on_sale',
    boarding_address: '西雅图港口邮轮码头',
    boarding_deadline: '15:00',
    itinerary: [
      { day: 1, port: '西雅图', title: '登船', description: '西雅图登船', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 2, port: '海上巡航', title: '海上巡航', description: '沿内湾航道北上', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 3, port: '朱诺', title: '岸上观光', description: '阿拉斯加首府观光', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 4, port: '史凯威', title: '岸上观光', description: '淘金小镇体验', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 5, port: '冰河湾国家公园', title: '岸上观光', description: '冰川崩解奇观', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 6, port: '凯奇坎', title: '岸上观光', description: '三文鱼之都观光', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 7, port: '海上巡航', title: '海上巡航', description: '返航途中尽享游轮设施', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 8, port: '西雅图', title: '离船', description: '抵达西雅图', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] }
    ],
    created_at: Time.current,
    updated_at: Time.current
  },
  # 地中海荣耀号 - 南北极航线（第1个航班）
  {
    cruise_ship_id: grandiosa.id,
    cruise_route_id: north_pole_route&.id,
    departure_date: Date.today + 60.days,
    return_date: Date.today + 74.days,
    duration_days: 15,
    duration_nights: 14,
    departure_port: '布宜诺斯艾利斯登船',
    arrival_port: '布宜诺斯艾利斯离船',
    status: 'on_sale',
    boarding_address: '布宜诺斯艾利斯邮轮港',
    boarding_deadline: '14:00',
    itinerary: [
      { day: 1, port: '布宜诺斯艾利斯', title: '登船', description: '阿根廷首都登船，开启南极探险之旅', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 2, port: '海上巡航', title: '海上巡航', description: '向南航行，准备穿越德雷克海峡', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 3, port: '乌斯怀亚', title: '岸上观光', description: '世界最南端城市，采购极地装备', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 4, port: '德雷克海峡', title: '海上巡航', description: '穿越德雷克海峡，南极环保讲座', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 5, port: '南设得兰群岛', title: '岸上观光', description: '登陆南极半岛，观赏企鹅栖息地', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 6, port: '天堂湾', title: '岸上观光', description: '南极最美海湾，冰川近距离接触', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 7, port: '勒梅尔海峡', title: '岸上观光', description: '南极明信片景点，巡航观赏', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 8, port: '库佛维尔岛', title: '岸上观光', description: '巴布亚企鹅繁殖地，野生动物摄影', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 9, port: '南极半岛', title: '岸上观光', description: '科考站参观，极地科学讲座', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 10, port: '德雷克海峡', title: '海上巡航', description: '返程穿越德雷克海峡', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 11, port: '海上巡航', title: '海上巡航', description: '继续北上返航', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 12, port: '乌斯怀亚', title: '岸上观光', description: '再访世界尽头，自由活动', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 13, port: '海上巡航', title: '海上巡航', description: '返航途中回顾旅程', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 14, port: '海上巡航', title: '海上巡航', description: '继续北上', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 15, port: '布宜诺斯艾利斯', title: '离船', description: '抵达布宜诺斯艾利斯，结束南极之旅', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] }
    ],
    created_at: Time.current,
    updated_at: Time.current
  },
  # 地中海荣耀号 - 南北极航线（第2个航班）
  {
    cruise_ship_id: grandiosa.id,
    cruise_route_id: north_pole_route&.id,
    departure_date: Date.today + 65.days,
    return_date: Date.today + 79.days,
    duration_days: 15,
    duration_nights: 14,
    departure_port: '布宜诺斯艾利斯登船',
    arrival_port: '布宜诺斯艾利斯离船',
    status: 'on_sale',
    boarding_address: '布宜诺斯艾利斯邮轮港',
    boarding_deadline: '14:00',
    itinerary: [
      { day: 1, port: '布宜诺斯艾利斯', title: '登船', description: '阿根廷首都登船', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 2, port: '海上巡航', title: '海上巡航', description: '向南航行', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 3, port: '乌斯怀亚', title: '岸上观光', description: '世界最南端城市', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 4, port: '德雷克海峡', title: '海上巡航', description: '穿越德雷克海峡', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 5, port: '南设得兰群岛', title: '岸上观光', description: '登陆南极半岛', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 6, port: '天堂湾', title: '岸上观光', description: '南极最美海湾', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 7, port: '勒梅尔海峡', title: '岸上观光', description: '南极明信片景点', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 8, port: '库佛维尔岛', title: '岸上观光', description: '企鹅繁殖地', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 9, port: '南极半岛', title: '岸上观光', description: '科考站参观', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 10, port: '德雷克海峡', title: '海上巡航', description: '返程穿越德雷克海峡', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 11, port: '海上巡航', title: '海上巡航', description: '继续北上返航', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 12, port: '乌斯怀亚', title: '岸上观光', description: '再访世界尽头', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 13, port: '海上巡航', title: '海上巡航', description: '返航途中', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 14, port: '海上巡航', title: '海上巡航', description: '继续北上', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 15, port: '布宜诺斯艾利斯', title: '离船', description: '抵达布宜诺斯艾利斯', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] }
    ],
    created_at: Time.current,
    updated_at: Time.current
  },
  # 地中海传奇号 - 欧洲河轮航线（第1个航班）
  {
    cruise_ship_id: fantasia.id,
    cruise_route_id: europe_river_route&.id,
    departure_date: Date.today + 36.days,
    return_date: Date.today + 43.days,
    duration_days: 8,
    duration_nights: 7,
    departure_port: '阿姆斯特丹登船',
    arrival_port: '布达佩斯离船',
    status: 'on_sale',
    boarding_address: '阿姆斯特丹中央车站码头',
    boarding_deadline: '16:00',
    itinerary: [
      { day: 1, port: '阿姆斯特丹', title: '登船', description: '荷兰首都登船，运河之城游览', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 2, port: '科隆', title: '岸上观光', description: '参观科隆大教堂，莱茵河畔古城', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 3, port: '科布伦茨', title: '岸上观光', description: '莱茵河与摩泽尔河交汇处，德意志之角', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 4, port: '吕德斯海姆', title: '岸上观光', description: '莱茵河谷葡萄酒小镇，酒窖品酒', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 5, port: '维尔茨堡', title: '岸上观光', description: '巴洛克风格主教宫，世界文化遗产', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 6, port: '纽伦堡', title: '岸上观光', description: '中世纪古城，纽伦堡审判地', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 7, port: '维也纳', title: '岸上观光', description: '奥地利首都，音乐之都巡礼', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 8, port: '布达佩斯', title: '离船', description: '匈牙利首都，多瑙河明珠', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] }
    ],
    created_at: Time.current,
    updated_at: Time.current
  },
  # 地中海传奇号 - 欧洲河轮航线（第2个航班）
  {
    cruise_ship_id: fantasia.id,
    cruise_route_id: europe_river_route&.id,
    departure_date: Date.today + 47.days,
    return_date: Date.today + 54.days,
    duration_days: 8,
    duration_nights: 7,
    departure_port: '布达佩斯登船',
    arrival_port: '阿姆斯特丹离船',
    status: 'on_sale',
    boarding_address: '布达佩斯多瑙河码头',
    boarding_deadline: '16:00',
    itinerary: [
      { day: 1, port: '布达佩斯', title: '登船', description: '匈牙利首都登船，多瑙河明珠', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 2, port: '维也纳', title: '岸上观光', description: '奥地利首都，音乐之都巡礼', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 3, port: '梅尔克', title: '岸上观光', description: '梅尔克修道院，瓦豪河谷葡萄酒产区', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 4, port: '帕绍', title: '岸上观光', description: '三河城，多瑙河、因河、伊尔茨河交汇', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 5, port: '雷根斯堡', title: '岸上观光', description: '巴伐利亚古城，世界文化遗产', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 6, port: '班贝格', title: '岸上观光', description: '小威尼斯，中世纪建筑群', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 7, port: '法兰克福', title: '岸上观光', description: '德国金融中心，老城罗马广场', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 8, port: '阿姆斯特丹', title: '离船', description: '抵达阿姆斯特丹，结束河轮之旅', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] }
    ],
    created_at: Time.current,
    updated_at: Time.current
  },
  # 地中海传奇号 - 欧洲河轮航线（第3个航班）
  {
    cruise_ship_id: fantasia.id,
    cruise_route_id: europe_river_route&.id,
    departure_date: Date.today + 51.days,
    return_date: Date.today + 58.days,
    duration_days: 8,
    duration_nights: 7,
    departure_port: '阿姆斯特丹登船',
    arrival_port: '布达佩斯离船',
    status: 'on_sale',
    boarding_address: '阿姆斯特丹中央车站码头',
    boarding_deadline: '16:00',
    itinerary: [
      { day: 1, port: '阿姆斯特丹', title: '登船', description: '荷兰首都登船', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 2, port: '科隆', title: '岸上观光', description: '科隆大教堂', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 3, port: '科布伦茨', title: '岸上观光', description: '德意志之角', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 4, port: '吕德斯海姆', title: '岸上观光', description: '葡萄酒小镇', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 5, port: '维尔茨堡', title: '岸上观光', description: '主教宫参观', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 6, port: '纽伦堡', title: '岸上观光', description: '中世纪古城', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 7, port: '维也纳', title: '岸上观光', description: '音乐之都', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 8, port: '布达佩斯', title: '离船', description: '抵达布达佩斯', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] }
    ],
    created_at: Time.current,
    updated_at: Time.current
  },
  # 地中海辉煌号 - 中东航线（第1个航班）
  {
    cruise_ship_id: bellissima.id,
    cruise_route_id: middle_east_route&.id,
    departure_date: Date.today + 31.days,
    return_date: Date.today + 38.days,
    duration_days: 8,
    duration_nights: 7,
    departure_port: '迪拜登船',
    arrival_port: '迪拜离船',
    status: 'on_sale',
    boarding_address: '迪拜拉希德港邮轮码头',
    boarding_deadline: '15:00',
    itinerary: [
      { day: 1, port: '迪拜', title: '登船', description: '迪拜登船，现代奇迹之城', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 2, port: '阿布扎比', title: '岸上观光', description: '阿联酋首都，参观谢赫扎耶德大清真寺、卢浮宫阿布扎比', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 3, port: '多哈', title: '岸上观光', description: '卡塔尔首都，瓦其夫老市场、伊斯兰艺术博物馆', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 4, port: '巴林', title: '岸上观光', description: '巴林王国，巴林堡、珍珠博物馆', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 5, port: '科威特', title: '岸上观光', description: '科威特城，科威特塔、大清真寺', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 6, port: '海上巡航', title: '海上巡航', description: '波斯湾巡航，享受游轮设施', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 7, port: '富查伊拉', title: '岸上观光', description: '阿联酋东海岸，富查伊拉古堡、潜水胜地', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 8, port: '迪拜', title: '离船', description: '返回迪拜，结束中东之旅', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] }
    ],
    created_at: Time.current,
    updated_at: Time.current
  },
  # 地中海辉煌号 - 中东航线（第2个航班）
  {
    cruise_ship_id: bellissima.id,
    cruise_route_id: middle_east_route&.id,
    departure_date: Date.today + 33.days,
    return_date: Date.today + 40.days,
    duration_days: 8,
    duration_nights: 7,
    departure_port: '迪拜登船',
    arrival_port: '迪拜离船',
    status: 'on_sale',
    boarding_address: '迪拜拉希德港邮轮码头',
    boarding_deadline: '15:00',
    itinerary: [
      { day: 1, port: '迪拜', title: '登船', description: '迪拜登船', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 2, port: '阿布扎比', title: '岸上观光', description: '阿联酋首都观光', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 3, port: '多哈', title: '岸上观光', description: '卡塔尔首都', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 4, port: '巴林', title: '岸上观光', description: '巴林王国', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 5, port: '科威特', title: '岸上观光', description: '科威特城', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 6, port: '海上巡航', title: '海上巡航', description: '波斯湾巡航', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 7, port: '富查伊拉', title: '岸上观光', description: '阿联酋东海岸', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 8, port: '迪拜', title: '离船', description: '返回迪拜', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] }
    ],
    created_at: Time.current,
    updated_at: Time.current
  },
  # 海洋光谱号 - 西沙群岛航线（第1个航班）
  {
    cruise_ship_id: spectrum.id,
    cruise_route_id: xisha_islands_route&.id,
    departure_date: Date.today + 29.days,
    return_date: Date.today + 33.days,
    duration_days: 5,
    duration_nights: 4,
    departure_port: '三亚凤凰岛登船',
    arrival_port: '三亚凤凰岛离船',
    status: 'on_sale',
    boarding_address: '三亚凤凰岛国际邮轮码头',
    boarding_deadline: '14:00',
    itinerary: [
      { day: 1, port: '三亚', title: '登船', description: '三亚凤凰岛登船，开启西沙群岛探秘之旅', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 2, port: '海上巡航', title: '海上巡航', description: '南海巡航，西沙群岛海洋文化讲座', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 3, port: '全富岛', title: '岸上观光', description: '登陆全富岛，珊瑚白沙滩，浮潜观赏海底世界', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 4, port: '鸭公岛', title: '岸上观光', description: '渔民小岛体验，海鲜市场，渔家乐', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 5, port: '三亚', title: '离船', description: '返回三亚凤凰岛，结束西沙之旅', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] }
    ],
    created_at: Time.current,
    updated_at: Time.current
  },
  # 海洋光谱号 - 西沙群岛航线（第2个航班）
  {
    cruise_ship_id: spectrum.id,
    cruise_route_id: xisha_islands_route&.id,
    departure_date: Date.today + 39.days,
    return_date: Date.today + 43.days,
    duration_days: 5,
    duration_nights: 4,
    departure_port: '三亚凤凰岛登船',
    arrival_port: '三亚凤凰岛离船',
    status: 'on_sale',
    boarding_address: '三亚凤凰岛国际邮轮码头',
    boarding_deadline: '14:00',
    itinerary: [
      { day: 1, port: '三亚', title: '登船', description: '三亚凤凰岛登船', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 2, port: '海上巡航', title: '海上巡航', description: '南海巡航', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 3, port: '全富岛', title: '岸上观光', description: '登陆全富岛', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 4, port: '鸭公岛', title: '岸上观光', description: '渔民小岛体验', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 5, port: '三亚', title: '离船', description: '返回三亚凤凰岛', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] }
    ],
    created_at: Time.current,
    updated_at: Time.current
  },
  # 海洋光谱号 - 西沙群岛航线（第3个航班）
  {
    cruise_ship_id: spectrum.id,
    cruise_route_id: xisha_islands_route&.id,
    departure_date: Date.today + 43.days,
    return_date: Date.today + 47.days,
    duration_days: 5,
    duration_nights: 4,
    departure_port: '三亚凤凰岛登船',
    arrival_port: '三亚凤凰岛离船',
    status: 'on_sale',
    boarding_address: '三亚凤凰岛国际邮轮码头',
    boarding_deadline: '14:00',
    itinerary: [
      { day: 1, port: '三亚', title: '登船', description: '三亚凤凰岛登船', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 2, port: '海上巡航', title: '海上巡航', description: '南海巡航', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 3, port: '全富岛', title: '岸上观光', description: '登陆全富岛', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 4, port: '鸭公岛', title: '岸上观光', description: '渔民小岛体验', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
      { day: 5, port: '三亚', title: '离船', description: '返回三亚凤凰岛', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] }
    ],
    created_at: Time.current,
    updated_at: Time.current
  }
]

CruiseSailing.insert_all(cruise_sailings_data)

# ==================== 舱房类型数据 ====================

# 预生成舱房图片数组（避免重复调用）
cabin_images = ImageSeedHelper.random_images_from_category(:cruise_cabins, count: 6)

cabin_types_data = [
  # 海洋光谱号 - 舱房类型
  {
    cruise_ship_id: spectrum.id,
    name: '阳台房',
    category: 'balcony',
    floor_range: '6-13层',
    area: 18,
    has_balcony: true,
    has_window: true,
    max_occupancy: 4,
    description: '独立观海阳台',
    image_urls: [cabin_images[0], cabin_images[1]].compact,
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_ship_id: spectrum.id,
    name: '海景房',
    category: 'ocean_view',
    floor_range: '6-10层',
    area: 16,
    has_balcony: false,
    has_window: true,
    max_occupancy: 3,
    description: '超大观海窗户',
    image_urls: [cabin_images[2]].compact,
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_ship_id: spectrum.id,
    name: '内舱房',
    category: 'interior',
    floor_range: '3-10层',
    area: 14,
    has_balcony: false,
    has_window: false,
    max_occupancy: 2,
    description: '性价比之选',
    image_urls: [cabin_images[3]].compact,
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_ship_id: spectrum.id,
    name: '套房',
    category: 'suite',
    floor_range: '11-14层',
    area: 35,
    has_balcony: true,
    has_window: true,
    max_occupancy: 4,
    description: '尊享VIP权益',
    image_urls: [cabin_images[4], cabin_images[5]].compact,
    created_at: Time.current,
    updated_at: Time.current
  },
  # 地中海辉煌号 - 舱房类型
  {
    cruise_ship_id: bellissima.id,
    name: '阳台房',
    category: 'balcony',
    floor_range: '7-11层',
    area: 20,
    has_balcony: true,
    has_window: true,
    max_occupancy: 4,
    description: '地中海风格装饰，享受海风拂面',
    image_urls: [cabin_images[0]].compact,
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_ship_id: bellissima.id,
    name: '海景房',
    category: 'oceanview',
    floor_range: '5-10层',
    area: 18,
    has_balcony: false,
    has_window: true,
    max_occupancy: 3,
    description: '观景之选，全景落地窗',
    image_urls: [cabin_images[2]].compact,
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_ship_id: bellissima.id,
    name: '内舱房',
    category: 'interior',
    floor_range: '4-9层',
    area: 15,
    has_balcony: false,
    has_window: false,
    max_occupancy: 2,
    description: '经济实惠之选',
    image_urls: [cabin_images[3]].compact,
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_ship_id: bellissima.id,
    name: '海景房',
    category: 'ocean_view',
    floor_range: '6-10层',
    area: 17,
    has_balcony: false,
    has_window: true,
    max_occupancy: 3,
    description: '大型观景窗，明亮通透',
    image_urls: [cabin_images[2]].compact,
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_ship_id: bellissima.id,
    name: 'MSC游艘俱乐部套房',
    category: 'suite',
    floor_range: '14-16层',
    area: 48,
    has_balcony: true,
    has_window: true,
    max_occupancy: 4,
    description: '尊享俱乐部服务，专属餐厅',
    image_urls: [cabin_images[4], cabin_images[5]].compact,
    created_at: Time.current,
    updated_at: Time.current
  },
  # 爱达新星号 - 舱房类型
  {
    cruise_ship_id: aida_nova.id,
    name: '阳台房',
    category: 'balcony',
    floor_range: '8-14层',
    area: 22,
    has_balcony: true,
    has_window: true,
    max_occupancy: 4,
    description: '现代简约风格，大面积阳台',
    image_urls: [cabin_images[1], cabin_images[2]].compact,
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_ship_id: aida_nova.id,
    name: '海景房',
    category: 'ocean_view',
    floor_range: '6-12层',
    area: 18,
    has_balcony: false,
    has_window: true,
    max_occupancy: 3,
    description: '全景落地窗，180度海景',
    image_urls: [cabin_images[4]].compact,
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_ship_id: aida_nova.id,
    name: '内舱房',
    category: 'interior',
    floor_range: '4-10层',
    area: 16,
    has_balcony: false,
    has_window: false,
    max_occupancy: 2,
    description: '经济型选择，舒适空间',
    image_urls: [cabin_images[3]].compact,
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_ship_id: aida_nova.id,
    name: '家庭套房',
    category: 'suite',
    floor_range: '12-15层',
    area: 42,
    has_balcony: true,
    has_window: true,
    max_occupancy: 6,
    description: '适合家庭出游，独立客厅和卧室',
    image_urls: [cabin_images[5], cabin_images[0]].compact,
    created_at: Time.current,
    updated_at: Time.current
  },
  # 地中海荣耀号 - 舱房类型
  {
    cruise_ship_id: grandiosa.id,
    name: '阳台房',
    category: 'balcony',
    floor_range: '8-14层',
    area: 21,
    has_balcony: true,
    has_window: true,
    max_occupancy: 4,
    description: '地中海风格，宽敞阳台',
    image_urls: [cabin_images[1]].compact,
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_ship_id: grandiosa.id,
    name: '内舱房',
    category: 'interior',
    floor_range: '5-10层',
    area: 16,
    has_balcony: false,
    has_window: false,
    max_occupancy: 2,
    description: '经济实惠之选',
    image_urls: [cabin_images[3]].compact,
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_ship_id: grandiosa.id,
    name: '游艇俱乐部套房',
    category: 'suite',
    floor_range: '15-18层',
    area: 45,
    has_balcony: true,
    has_window: true,
    max_occupancy: 4,
    description: '尊享俱乐部服务，专属餐厅和泳池',
    image_urls: [cabin_images[4]].compact,
    created_at: Time.current,
    updated_at: Time.current
  },
  # 地中海传奇号 - 舱房类型
  {
    cruise_ship_id: fantasia.id,
    name: '阳台房',
    category: 'balcony',
    floor_range: '7-12层',
    area: 19,
    has_balcony: true,
    has_window: true,
    max_occupancy: 4,
    description: '私密阳台，海景房',
    image_urls: [cabin_images[0]].compact,
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_ship_id: fantasia.id,
    name: '内舱房',
    category: 'interior',
    floor_range: '4-9层',
    area: 14,
    has_balcony: false,
    has_window: false,
    max_occupancy: 2,
    description: '经济型选择',
    image_urls: [cabin_images[3]].compact,
    created_at: Time.current,
    updated_at: Time.current
  },
  # 海洋和悦号 - 舱房类型
  {
    cruise_ship_id: harmony.id,
    name: '阳台房',
    category: 'balcony',
    floor_range: '8-15层',
    area: 20,
    has_balcony: true,
    has_window: true,
    max_occupancy: 4,
    description: '中央公园景观阳台房',
    image_urls: [cabin_images[1]].compact,
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_ship_id: harmony.id,
    name: '海景房',
    category: 'ocean_view',
    floor_range: '7-12层',
    area: 17,
    has_balcony: false,
    has_window: true,
    max_occupancy: 3,
    description: '大型观景窗',
    image_urls: [cabin_images[2]].compact,
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_ship_id: harmony.id,
    name: '内舱房',
    category: 'interior',
    floor_range: '4-10层',
    area: 15,
    has_balcony: false,
    has_window: false,
    max_occupancy: 2,
    description: '性价比之选',
    image_urls: [cabin_images[3]].compact,
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_ship_id: harmony.id,
    name: '皇家套房',
    category: 'suite',
    floor_range: '16-18层',
    area: 50,
    has_balcony: true,
    has_window: true,
    max_occupancy: 6,
    description: '皇家尊享，专属管家服务',
    image_urls: [cabin_images[5]].compact,
    created_at: Time.current,
    updated_at: Time.current
  }
]

CabinType.insert_all(cabin_types_data)
puts "    ✓ 已加载 #{cabin_types_data.size} 种舱房类型"

# ==================== 商家产品数据 ====================
puts "  → 正在加载商家产品数据..."

# 商家列表（模拟不同旅行社/OTA平台）
merchants = [
  { name: '飞猪旅行', badge: '近期热销', discount: 0 },
  { name: '携程旅行', badge: nil, discount: 100 },
  { name: '途牛旅游', badge: '低价之选', discount: 150 }
]

# 获取所有航班
all_sailings = CruiseSailing.where(data_version: '0').includes(:cruise_ship)

# 为每个航班的每种舱房类型创建产品
cruise_products_data = []

all_sailings.each do |sailing|
  ship = sailing.cruise_ship
  cabin_types = ship.cabin_types
  
  cabin_types.each do |cabin_type|
    # 根据舱房类型设置价格（基础价格 + 航线调整 + 船只调整）
    base_price = case cabin_type.category
    when 'interior' then 1200
    when 'ocean_view' then 1600
    when 'balcony' then 2000
    when 'suite' then 3500
    else 1500
    end
    
    # 航线调整：日韩航线较便宜，东南亚航线较贵
    route_multiplier = case sailing.cruise_route.region
    when 'japan_korea' then 1.0
    when 'southeast_asia' then 1.3
    else 1.0
    end
    
    # 船只调整：爱达新星号较贵
    ship_multiplier = case ship.name
    when '海洋光谱号' then 1.0
    when '地中海辉煌号' then 1.05
    when '爱达新星号' then 1.15
    else 1.0
    end
    
    # 天数调整
    duration_multiplier = sailing.duration_days / 6.0
    
    # 计算基础价格
    price_per_person = (base_price * route_multiplier * ship_multiplier * duration_multiplier).round(1)
    
    # 为每个舱房类型创建2-3个商家产品（不同价格）
    merchants.sample(rand(2..3)).each do |merchant|
      final_price = price_per_person - merchant[:discount]
      
      cruise_products_data << {
        cruise_sailing_id: sailing.id,
        cabin_type_id: cabin_type.id,
        merchant_name: merchant[:name],
        badge: merchant[:badge],
        price_per_person: final_price,
        occupancy_requirement: 2,
        stock: rand(5..20),
        sales_count: rand(0..50),
        is_refundable: [true, false].sample,
        requires_confirmation: false,
        status: 'on_sale',
        data_version: '0',
        created_at: Time.current,
        updated_at: Time.current
      }
    end
  end
end

CruiseProduct.insert_all(cruise_products_data) if cruise_products_data.any?
puts "    ✓ 已加载 #{cruise_products_data.size} 个商家产品"

puts "✓ cruises_v1 数据包加载完成"
