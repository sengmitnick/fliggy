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
# rails runner "load Rails.root.join('app/validators/support/data_packs/v1/cruises.rb')"

puts "正在加载 cruises_v1 数据包..."

# ==================== 游轮公司数据 ====================

cruise_lines_data = [
  {
    name: '皇家加勒比国际游轮',
    name_en: 'Royal Caribbean International',
    logo_url: 'https://images.unsplash.com/photo-1548574505-5e239809ee19?w=200&h=200&fit=crop',
    description: '全球豪华游轮领导品牌，拥有超量子系列、绿洲系列等多个创新船队',
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    name: '地中海邮轮',
    name_en: 'MSC Cruises',
    logo_url: 'https://images.unsplash.com/photo-1563298723-dcfebaa392e3?w=200&h=200&fit=crop',
    description: '欧洲第一、世界第四大邮轮公司，提供地中海特色服务',
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    name: '爱达邮轮',
    name_en: 'AIDA Cruises',
    logo_url: 'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=200&h=200&fit=crop',
    description: '德国邮轮品牌，以年轻时尚的邮轮体验著称',
    created_at: Time.current,
    updated_at: Time.current
  }
]

CruiseLine.insert_all(cruise_lines_data)

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
    image_url: 'https://images.unsplash.com/photo-1540821924489-7690c70c4eac?w=800&h=600&fit=crop',
    tonnage: 168666,
    passenger_capacity: 4246,
    features: ['超量子系列首艘邮轮', '甲板跳伞', '正宗川菜料理', '套房专享皇家府邸'],
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_line_id: msc_cruises.id,
    name: '地中海辉煌号',
    name_en: 'MSC Bellissima',
    image_url: 'https://images.unsplash.com/photo-1563299796-17596ed6b017?w=800&h=600&fit=crop',
    tonnage: 171598,
    passenger_capacity: 4500,
    features: ['米其林星级餐厅', '豪华购物长廊', '海上水上乐园'],
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_line_id: aida_cruises.id,
    name: '爱达新星号',
    name_en: 'AIDA Nova',
    image_url: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&h=600&fit=crop',
    tonnage: 183900,
    passenger_capacity: 5200,
    features: ['环保LNG动力', '全景观景台', '海上啤酒花园'],
    created_at: Time.current,
    updated_at: Time.current
  }
]

CruiseShip.insert_all(cruise_ships_data)
# Regenerate slugs for FriendlyId (insert_all bypasses callbacks)
CruiseShip.find_each(&:save)

# ==================== 航线数据 ====================

cruise_routes_data = [
  { name: '日韩', region: 'japan_korea', icon_url: 'tourism/邮轮游.png', created_at: Time.current, updated_at: Time.current },
  { name: '三峡', region: 'yangtze_river', icon_url: 'tourism/邮轮游.png', created_at: Time.current, updated_at: Time.current },
  { name: '南北极', region: 'north_pole', icon_url: 'tourism/邮轮游.png', created_at: Time.current, updated_at: Time.current },
  { name: '东南亚', region: 'southeast_asia', icon_url: 'tourism/邮轮游.png', created_at: Time.current, updated_at: Time.current },
  { name: '地中海', region: 'mediterranean', icon_url: 'tourism/邮轮游.png', created_at: Time.current, updated_at: Time.current },
  { name: '阿拉斯加', region: 'alaska', icon_url: 'tourism/邮轮游.png', created_at: Time.current, updated_at: Time.current },
  { name: '欧洲河轮', region: 'europe_river', icon_url: 'tourism/邮轮游.png', created_at: Time.current, updated_at: Time.current },
  { name: '加勒比', region: 'caribbean', icon_url: 'tourism/邮轮游.png', created_at: Time.current, updated_at: Time.current },
  { name: '中东', region: 'middle_east', icon_url: 'tourism/邮轮游.png', created_at: Time.current, updated_at: Time.current },
  { name: '西沙群岛', region: 'xisha_islands', icon_url: 'tourism/邮轮游.png', created_at: Time.current, updated_at: Time.current }
]

CruiseRoute.insert_all(cruise_routes_data)

# ==================== 游轮班次数据 ====================

# 获取船只和航线ID
spectrum = CruiseShip.find_by(name: '海洋光谱号')
bellissima = CruiseShip.find_by(name: '地中海辉煌号')
aida_nova = CruiseShip.find_by(name: '爱达新星号')
japan_korea_route = CruiseRoute.find_by(region: 'japan_korea')
mediterranean_route = CruiseRoute.find_by(region: 'mediterranean')
southeast_asia_route = CruiseRoute.find_by(region: 'southeast_asia')

cruise_sailings_data = [
  # 海洋光谱号 - 日韩航线
  {
    cruise_ship_id: spectrum.id,
    cruise_route_id: japan_korea_route.id,
    departure_date: Date.parse('2026-01-23'),
    return_date: Date.parse('2026-01-28'),
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
        images: ['https://images.unsplash.com/photo-1583417319070-4a69db38a482']
      },
      { 
        day: 2, 
        port: '海上巡航', 
        title: '岸上观光',
        description: "行程描述 从欧洲到美洲，从澳洲到北极，尝鲜之旅，远到想不到！尝遍世界之味，新开辟的川菜、茶餐厅、铁板烧、中式茶饮更为你带来远游后家的暖心；海上超大的自助餐厅静候每一位大胃美食家的光临。\n\n船上设施 海洋光谱号拥有丰富的娱乐设施，包括北极星观景台、南极球模拟跳伞体验、甲板跳伞、海上碰碰车、室内游泳池等。您还可以参加瑜伽课程、健身房锻炼，或在皇家剧院欣赏百老汇风格的演出。\n\n餐饮选择 主餐厅提供中西式自助早餐，午餐和晚餐可选择正式的点餐服务。特色餐厅包括日式铁板烧、川菜馆、意大利餐厅等。14楼的自助餐厅提供全天候美食，让您随时享用各国料理。",
        images: ['https://images.unsplash.com/photo-1605833556294-ea5530136475', 'https://images.unsplash.com/photo-1540541338287-41700207dee6']
      },
      { 
        day: 3, 
        port: '冲绳', 
        title: '岸上观光',
        description: "行程描述 今天我们将抵达日本冲绳那霸港。冲绳被誉为日本的夏威夷，拥有迷人的海滩、独特的琉球文化和美丽的水下世界。\n\n推荐活动 您可以参加岸上游览项目：首里城探访（琉球王国的宫殿遗址，世界文化遗产）、美丽海水族馆参观（世界级的水族馆，拥有巨大的黑潮之海水槽）、国际通商店街购物（冲绳最繁华的商业街，可以购买当地特产）。\n\n美食推荐 不要错过冲绳特色美食：冲绳荞麦面、塔可饭、海葡萄、苦瓜炒蛋、紫薯塔等。国际通沿街有许多餐厅和小吃店可以品尝。\n\n温馨提示 冲绳气候温暖，请携带防晒用品。岸上游览时间约为8小时，请在16:00前返回船上。",
        images: ['https://images.unsplash.com/photo-1598127992614-ee836c0e6e69', 'https://images.unsplash.com/photo-1528360983277-13d401cdc186']
      },
      { 
        day: 4, 
        port: '福冈', 
        title: '岸上观光',
        description: "行程描述 今天我们将停靠福冈博多港。福冈是日本九州地区最大的城市，以美食、购物和温泉而闻名。\n\n推荐活动 您可以前往太宰府天满宫参拜（日本著名的学问之神神社）、福冈塔观景（高234米，可俯瞰整个城市和博多湾）、栉田神社游览（福冈最古老的神社之一）、天神地下街购物（九州最大的地下商业街）。\n\n美食推荐 福冈拉面是必尝美食，尤其是博多豚骨拉面。一兰拉面、一风堂、博多だるま等都是知名店铺。此外还有明太子、牛杂锅、鸡肉水炊等当地特色。\n\n购物天堂 天神地区是福冈的购物中心，拥有三越、大丸、PARCO等百货商场。博多运河城是大型综合购物娱乐设施。\n\n温馨提示 岸上游览时间约为9小时，请在17:00前返回船上。",
        images: ['https://images.unsplash.com/photo-1590559899731-a382839e5549', 'https://images.unsplash.com/photo-1528360983277-13d401cdc186']
      },
      { 
        day: 5, 
        port: '海上巡航', 
        title: '岸上观光',
        description: "行程描述 今天是海上巡航日，您可以尽情享受游轮上的各种设施和娱乐活动。\n\n甲板活动 在露天甲板上享受日光浴，参加游泳池派对，或在热水按摩池中放松身心。14楼的北极星观景台将在上午10:00-12:00、下午15:00-17:00开放，登上距海平面90米的观景臂，360度俯瞰壮丽海景。\n\n娱乐表演 晚上20:00在皇家剧院将上演精彩的百老汇风格歌舞表演《音乐之声》。在270度观景厅，您还可以欣赏结合了科技与艺术的多媒体表演。\n\n特色体验 南极球模拟跳伞体验（需预约）、甲板跳伞、海上碰碰车、攀岩墙等刺激项目等您挑战。喜欢安静的游客可以前往图书馆阅读，或参加摄影、绘画等艺术工作坊。\n\n餐饮活动 晚上将举行船长欢迎晚宴，这是一个正式的用餐场合，建议穿着正装出席。主餐厅将提供精致的多道式西餐。",
        images: ['https://images.unsplash.com/photo-1571896349842-33c89424de2d', 'https://images.unsplash.com/photo-1578894381163-e72c17f2d45f']
      },
      { 
        day: 6, 
        port: '上海', 
        title: '离船',
        description: "行程描述 今天早晨我们将抵达上海吴淞口国际邮轮码头，结束这次精彩的游轮之旅。\n\n离船安排 游轮预计早上07:00抵达，办理离船手续后您可以在08:00-10:00之间离船。请在昨晚将大件行李放在房间门口，我们会帮您送至码头。随身贵重物品请自行携带。\n\n结账事宜 如果您的房卡绑定了信用卡，所有船上消费将自动结算。如需查看账单明细，可在离船前一天到服务台索取。\n\n码头交通 码头有出租车、网约车上客点，也有地铁3号线宝杨路站（步行约15分钟）。如需前往市区，建议提前预约接送服务。\n\n感谢致辞 感谢您选择海洋光谱号，期待再次为您服务！祝您旅途愉快！",
        images: ['https://images.unsplash.com/photo-1583417319070-4a69db38a482']
      }
    ],
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_ship_id: spectrum.id,
    cruise_route_id: japan_korea_route.id,
    departure_date: Date.parse('2026-01-28'),
    return_date: Date.parse('2026-02-01'),
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
        images: ['https://images.unsplash.com/photo-1583417319070-4a69db38a482']
      },
      { 
        day: 2, 
        port: '济州岛', 
        title: '岸上观光',
        description: "行程描述 今天我们将抵达韩国济州岛。济州岛是韩国最大的岛屿，被誉为韩国的夏威夷，以其独特的火山地貌、美丽的海岸线和丰富的自然景观而闻名。\n\n推荐活动 您可以参加岸上游览：城山日出峰登顶（世界自然遗产，火山口观景）、涉地可支海岸漫步（热门韩剧拍摄地）、泰迪熊博物馆参观（适合亲子游）、东门市场品尝美食（当地海鲜市场）。\n\n美食推荐 济州岛特色美食包括黑猪肉烤肉、鲍鱼粥、海鲜火锅、橘子巧克力等。东门市场和中央地下商街有许多小吃摊位。\n\n购物指南 新罗免税店、乐天免税店提供各类国际品牌商品。当地特产包括济州柑橘、绿茶制品、黑猪肉制品、海产品等。\n\n温馨提示 岸上游览时间约为8小时，请在17:00前返回船上。韩国使用韩元，建议提前兑换或使用信用卡。",
        images: ['https://images.unsplash.com/photo-1578193661830-1c2b0f29b5ce', 'https://images.unsplash.com/photo-1583417319070-4a69db38a482']
      },
      { 
        day: 3, 
        port: '釜山', 
        title: '岸上观光',
        description: "行程描述 今天我们将停靠韩国第二大城市釜山。釜山是韩国最重要的港口城市，拥有美丽的海滩、现代化的都市风光和丰富的历史文化。\n\n推荐活动 海云台海滩漫步（韩国最著名的海滩）、甘川文化村探访（彩色房子艺术村，摄影胜地）、札嘎其海鲜市场体验（韩国最大的海鲜市场）、龙头山公园观景（釜山塔360度观景）、西面购物区逛街。\n\n美食推荐 釜山以海鲜闻名，必尝美食包括生鱼片、海鲜煎饼、猪肉汤饭、血肠、炸鸡配啤酒等。札嘎其市场可以购买海鲜后现场加工。\n\n购物天堂 西面地下街、光复路时尚街、新世界百货、乐天百货等购物场所应有尽有。釜山的化妆品和服饰价格相对首尔更优惠。\n\n温馨提示 岸上游览时间约为9小时，请在18:00前返回船上。釜山地铁便利，建议购买交通卡使用。",
        images: ['https://images.unsplash.com/photo-1538683270504-3f0e28616160', 'https://images.unsplash.com/photo-1583417319070-4a69db38a482']
      },
      { 
        day: 4, 
        port: '海上巡航', 
        title: '岸上观光',
        description: "行程描述 今天是海上巡航日，让您从岸上游览的疲惫中恢复过来，尽情享受游轮生活。\n\n休闲放松 在Spa温泉中心享受专业的按摩和美容护理服务（需额外付费），或在室内游泳池畅游，热水按摩池泡汤。喜欢安静的游客可以在图书馆阅读，或在观景休息室品茶聊天。\n\n亲子活动 海上历奇青少年活动中心为3-17岁的孩子提供分年龄段的托管服务和趣味活动，家长可以安心享受二人世界。14楼的南极球和甲板跳伞是孩子们的最爱。\n\n美食体验 午餐建议尝试14楼帆船自助餐厅的亚洲美食专区，有港式点心、日本寿司、东南亚咖喱等。晚餐可预约特色收费餐厅，如奥利弗意大利餐厅、泉·日式料理等。\n\n晚间娱乐 音乐厅将在晚上举办现场音乐演奏会，270度观景厅有多媒体表演秀，皇家赌场（仅在公海开放）提供各类博彩娱乐。",
        images: ['https://images.unsplash.com/photo-1540541338287-41700207dee6', 'https://images.unsplash.com/photo-1571896349842-33c89424de2d']
      },
      { 
        day: 5, 
        port: '上海', 
        title: '离船',
        description: "行程描述 今天早晨我们将返回上海吴淞口国际邮轮码头，结束这次愉快的韩国之旅。\n\n离船安排 游轮预计早上07:30抵达，08:30开始办理离船手续。请在昨晚22:00前将大件行李放在房间门口，贴上行李条。贵重物品、证件、药品请随身携带。\n\n早餐安排 离船当天早餐将在06:00-08:00在14楼帆船自助餐厅提供。如果您需要提早离船，可以选择打包早餐。\n\n结账提示 请在离船前到前台结清所有船上消费，或确认已绑定信用卡自动扣款。如有疑问请及时联系宾客服务台。\n\n后续交通 码头出口有出租车候客区、网约车上客点，也可以提前预约接送服务。前往市区约需40-60分钟（视路况而定）。\n\n再会致辞 感谢您选择海洋光谱号，期待下次再会！",
        images: ['https://images.unsplash.com/photo-1583417319070-4a69db38a482']
      }
    ],
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_ship_id: spectrum.id,
    cruise_route_id: japan_korea_route.id,
    departure_date: Date.parse('2026-02-05'),
    return_date: Date.parse('2026-02-10'),
    duration_days: 6,
    duration_nights: 5,
    departure_port: '上海登船',
    arrival_port: '上海离船',
    status: 'on_sale',
    boarding_address: '上海吴淞口国际邮轮码头 上海市宝山区吴淞口宝杨路1号',
    boarding_deadline: '14:30',
    itinerary: [
      { day: 1, port: '上海', title: '登船', description: "登船地点 上海吴淞口国际邮轮码头 上海市宝山区吴淞口宝杨路1号\n\n登船截止时间 14:30\n\n行程描述 欢迎来到上海宝山码头，开启您此次的游轮之旅。您可以到达港口后办理行李托运及登船手续，通过安检与海关后，便可凭房卡登船。祝您与您的家人共同享受这无与伦比的游轮假期！\n\n码头地址：上海吴淞口国际邮轮码头 上海市宝山区吴淞口宝杨路1号\n\n交通指南 地铁3号线宝杨路站下车步行约15分钟；驾车可导航至宝杨路1号，码头提供付费停车服务。", images: ['https://images.unsplash.com/photo-1583417319070-4a69db38a482'] },
      { day: 2, port: '海上巡航', title: '岸上观光', description: "行程描述 今天是海上巡航日，您可以尽情体验游轮上的各种设施和活动。\n\n船上设施 海洋光谱号拥有丰富的娱乐设施，包括北极星观景台、南极球模拟跳伞、甲板跳伞、海上碰碰车、室内游泳池等。您还可以参加瑜伽课程、健身房锻炼，或在皇家剧院欣赏精彩演出。\n\n餐饮选择 主餐厅提供中西式自助早餐，午餐和晚餐可选择正式的点餐服务。特色餐厅包括日式铁板烧、川菜馆、意大利餐厅等。14楼的自助餐厅提供全天候美食。", images: ['https://images.unsplash.com/photo-1605833556294-ea5530136475'] },
      { day: 3, port: '福冈', title: '岸上观光', description: "行程描述 今天我们将停靠福冈博多港。福冈是日本九州地区最大的城市，以美食、购物和温泉而闻名。\n\n推荐活动 您可以前往太宰府天满宫参拜、福冈塔观景、栉田神社游览、天神地下街购物。\n\n美食推荐 福冈拉面是必尝美食，尤其是博多豚骨拉面。一兰拉面、一风堂等都是知名店铺。\n\n温馨提示 岸上游览时间约为9小时，请在17:00前返回船上。", images: ['https://images.unsplash.com/photo-1590559899731-a382839e5549'] },
      { day: 4, port: '长崎', title: '岸上观光', description: "行程描述 今天我们将抵达长崎港。长崎是日本九州西岸的重要港口城市，拥有丰富的历史文化遗产。\n\n推荐活动 和平公园参观、哥拉巴园游览、长崎新地中华街逛街、稻佐山缆车登顶、大浦天主堂参观。\n\n美食推荐 长崎什锦面、佐世保汉堡、蜂蜜蛋糕、角煮馒头等。\n\n温馨提示 岸上游览时间约为8小时，请在17:00前返回船上。", images: ['https://images.unsplash.com/photo-1528360983277-13d401cdc186'] },
      { day: 5, port: '海上巡航', title: '岸上观光', description: "行程描述 今天是海上巡航日，让您从岸上游览中恢复精力，享受悠闲的海上时光。\n\n休闲放松 在Spa温泉中心享受专业按摩，或在热水按摩池中放松身心。\n\n美食体验 午餐可尝试14楼自助餐厅的亚洲美食专区。晚餐可预约特色收费餐厅。\n\n晚间娱乐 音乐厅将举办现场音乐会，270度观景厅有多媒体表演。", images: ['https://images.unsplash.com/photo-1571896349842-33c89424de2d'] },
      { day: 6, port: '上海', title: '离船', description: "行程描述 今天早晨我们将返回上海吴淞口国际邮轮码头。\n\n离船安排 游轮预计早上07:00抵达，办理离船手续后您可以在08:00-10:00之间离船。请在昨晚将大件行李放在房间门口。\n\n感谢致辞 感谢您选择海洋光谱号，期待再次为您服务！", images: ['https://images.unsplash.com/photo-1583417319070-4a69db38a482'] }
    ],
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_ship_id: spectrum.id,
    cruise_route_id: japan_korea_route.id,
    departure_date: Date.parse('2026-02-15'),
    return_date: Date.parse('2026-02-19'),
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
        images: ['https://images.unsplash.com/photo-1583417319070-4a69db38a482'] 
      },
      { 
        day: 2, 
        port: '海上巡航', 
        title: '海上巡航',
        description: "行程描述 今天是海上巡航日，您可以尽情享受游轮上的各种设施和娱乐活动。\n\n船上设施 海洋光谱号拥有丰富的娱乐设施，包括北极星观景台、南极球模拟跳伞体验、甲板跳伞、海上碰碰车、室内游泳池等。您还可以参加瑜伽课程、健身房锻炼，或在皇家剧院欣赏百老汇风格的演出。\n\n餐饮选择 主餐厅提供中西式自助早餐，午餐和晚餐可选择正式的点餐服务。特色餐厅包括日式铁板烧、川菜馆、意大利餐厅等。14楼的自助餐厅提供全天候美食，让您随时享用各国料理。\n\n娱乐活动 参加甲板派对、游泳池活动、健身课程，或在图书馆享受静谧时光。晚上可在270度观景厅欣赏多媒体表演秀。", 
        images: ['https://images.unsplash.com/photo-1605833556294-ea5530136475', 'https://images.unsplash.com/photo-1540541338287-41700207dee6'] 
      },
      { 
        day: 3, 
        port: '冲绳', 
        title: '岸上观光',
        description: "行程描述 今天我们将抵达日本冲绳那霸港。冲绳被誉为日本的夏威夷，拥有迷人的海滩、独特的琉球文化和美丽的水下世界。\n\n推荐活动 您可以参加岸上游览项目：首里城探访（琉球王国的宫殿遗址，世界文化遗产）、美丽海水族馆参观（世界级的水族馆，拥有巨大的黑潮之海水槽）、国际通商店街购物（冲绳最繁华的商业街，可以购买当地特产）。\n\n美食推荐 不要错过冲绳特色美食：冲绳荞麦面、塔可饭、海葡萄、苦瓜炒蛋、紫薯塔等。国际通沿街有许多餐厅和小吃店可以品尝。\n\n温馨提示 冲绳气候温暖，请携带防晒用品。岸上游览时间约为8小时，请在16:00前返回船上。", 
        images: ['https://images.unsplash.com/photo-1598127992614-ee836c0e6e69', 'https://images.unsplash.com/photo-1528360983277-13d401cdc186'] 
      },
      { 
        day: 4, 
        port: '海上巡航', 
        title: '海上巡航',
        description: "行程描述 今天是海上巡航日，让您从岸上游览的疲惫中恢复过来，尽情享受游轮生活。\n\n甲板活动 在露天甲板上享受日光浴，参加游泳池派对，或在热水按摩池中放松身心。14楼的北极星观景台将在上午10:00-12:00、下午15:00-17:00开放，登上距海平面90米的观景臂，360度俯瞰壮丽海景。\n\n休闲放松 在Spa温泉中心享受专业的按摩和美容护理服务（需额外付费），或在室内游泳池畅游，热水按摩池泡汤。喜欢安静的游客可以在图书馆阅读，或在观景休息室品茶聊天。\n\n晚间娱乐 晚上20:00在皇家剧院将上演精彩的百老汇风格歌舞表演。在270度观景厅，您还可以欣赏结合了科技与艺术的多媒体表演。", 
        images: ['https://images.unsplash.com/photo-1571896349842-33c89424de2d', 'https://images.unsplash.com/photo-1578894381163-e72c17f2d45f'] 
      },
      { 
        day: 5, 
        port: '香港', 
        title: '离船',
        description: "行程描述 今天早晨我们将返回香港启德邮轮码头，结束这次精彩的游轮之旅。\n\n离船安排 游轮预计早上07:00抵达，办理离船手续后您可以在08:00-10:00之间离船。请在昨晚将大件行李放在房间门口，我们会帮您送至码头。随身贵重物品请自行携带。\n\n结账事宜 如果您的房卡绑定了信用卡，所有船上消费将自动结算。如需查看账单明细，可在离船前一天到服务台索取。\n\n码头交通 码头有出租车、网约车上客点，也可乘坐5R巴士前往港铁九龙湾站。如需前往市区，建议提前预约接送服务。\n\n感谢致辞 感谢您选择海洋光谱号，期待再次为您服务！祝您旅途愉快！", 
        images: ['https://images.unsplash.com/photo-1583417319070-4a69db38a482'] 
      }
    ],
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_ship_id: spectrum.id,
    cruise_route_id: japan_korea_route.id,
    departure_date: Date.parse('2026-02-22'),
    return_date: Date.parse('2026-02-27'),
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
        images: ['https://images.unsplash.com/photo-1583417319070-4a69db38a482'] 
      },
      { 
        day: 2, 
        port: '济州岛', 
        title: '岸上观光',
        description: "行程描述 今天我们将抵达韩国济州岛。济州岛是韩国最大的岛屿，被誉为韩国的夏威夷，以其独特的火山地貌、美丽的海岸线和丰富的自然景观而闻名。\n\n推荐活动 您可以参加岸上游览：城山日出峰登顶（世界自然遗产，火山口观景）、涉地可支海岸漫步（热门韩剧拍摄地）、泰迪熊博物馆参观（适合亲子游）、东门市场品尝美食（当地海鲜市场）。\n\n美食推荐 济州岛特色美食包括黑猪肉烤肉、鲍鱼粥、海鲜火锅、橘子巧克力等。东门市场和中央地下商街有许多小吃摊位。\n\n购物指南 新罗免税店、乐天免税店提供各类国际品牌商品。当地特产包括济州柑橘、绿茶制品、黑猪肉制品、海产品等。\n\n温馨提示 岸上游览时间约为8小时，请在17:00前返回船上。韩国使用韩元，建议提前兑换或使用信用卡。", 
        images: ['https://images.unsplash.com/photo-1578193661830-1c2b0f29b5ce', 'https://images.unsplash.com/photo-1583417319070-4a69db38a482'] 
      },
      { 
        day: 3, 
        port: '釜山', 
        title: '岸上观光',
        description: "行程描述 今天我们将停靠韩国第二大城市釜山。釜山是韩国最重要的港口城市，拥有美丽的海滩、现代化的都市风光和丰富的历史文化。\n\n推荐活动 海云台海滩漫步（韩国最著名的海滩）、甘川文化村探访（彩色房子艺术村，摄影胜地）、札嘎其海鲜市场体验（韩国最大的海鲜市场）、龙头山公园观景（釜山塔360度观景）、西面购物区逛街。\n\n美食推荐 釜山以海鲜闻名，必尝美食包括生鱼片、海鲜煎饼、猪肉汤饭、血肠、炸鸡配啤酒等。札嘎其市场可以购买海鲜后现场加工。\n\n购物天堂 西面地下街、光复路时尚街、新世界百货、乐天百货等购物场所应有尽有。釜山的化妆品和服饰价格相对首尔更优惠。\n\n温馨提示 岸上游览时间约为9小时，请在18:00前返回船上。釜山地铁便利，建议购买交通卡使用。", 
        images: ['https://images.unsplash.com/photo-1538683270504-3f0e28616160', 'https://images.unsplash.com/photo-1583417319070-4a69db38a482'] 
      },
      { 
        day: 4, 
        port: '福冈', 
        title: '岸上观光',
        description: "行程描述 今天我们将停靠福冈博多港。福冈是日本九州地区最大的城市，以美食、购物和温泉而闻名。\n\n推荐活动 您可以前往太宰府天满宫参拜（日本著名的学问之神神社）、福冈塔观景（高234米，可俯瞰整个城市和博多湾）、栉田神社游览（福冈最古老的神社之一）、天神地下街购物（九州最大的地下商业街）。\n\n美食推荐 福冈拉面是必尝美食，尤其是博多豚骨拉面。一兰拉面、一风堂、博多だるま等都是知名店铺。此外还有明太子、牛杂锅、鸡肉水炊等当地特色。\n\n购物天堂 天神地区是福冈的购物中心，拥有三越、大丸、PARCO等百货商场。博多运河城是大型综合购物娱乐设施。\n\n温馨提示 岸上游览时间约为9小时，请在17:00前返回船上。", 
        images: ['https://images.unsplash.com/photo-1590559899731-a382839e5549', 'https://images.unsplash.com/photo-1528360983277-13d401cdc186'] 
      },
      { 
        day: 5, 
        port: '海上巡航', 
        title: '海上巡航',
        description: "行程描述 今天是海上巡航日，让您从岸上游览中恢复精力，享受悠闲的海上时光。\n\n休闲放松 在Spa温泉中心享受专业按摩，或在热水按摩池中放松身心。喜欢安静的游客可以在图书馆阅读，或在观景休息室品茶聊天。\n\n亲子活动 海上历奇青少年活动中心为3-17岁的孩子提供分年龄段的托管服务和趣味活动，家长可以安心享受二人世界。14楼的南极球和甲板跳伞是孩子们的最爱。\n\n美食体验 午餐建议尝试14楼帆船自助餐厅的亚洲美食专区，有港式点心、日本寿司、东南亚咖喱等。晚餐可预约特色收费餐厅，如奥利弗意大利餐厅、泉·日式料理等。\n\n晚间娱乐 音乐厅将在晚上举办现场音乐演奏会，270度观景厅有多媒体表演秀，皇家赌场（仅在公海开放）提供各类博彩娱乐。", 
        images: ['https://images.unsplash.com/photo-1571896349842-33c89424de2d', 'https://images.unsplash.com/photo-1540541338287-41700207dee6'] 
      },
      { 
        day: 6, 
        port: '上海', 
        title: '离船',
        description: "行程描述 今天早晨我们将返回上海吴淞口国际邮轮码头，结束这次愉快的韩国日本之旅。\n\n离船安排 游轮预计早上07:30抵达，08:30开始办理离船手续。请在昨晚22:00前将大件行李放在房间门口，贴上行李条。贵重物品、证件、药品请随身携带。\n\n早餐安排 离船当天早餐将在06:00-08:00在14楼帆船自助餐厅提供。如果您需要提早离船，可以选择打包早餐。\n\n结账提示 请在离船前到前台结清所有船上消费，或确认已绑定信用卡自动扣款。如有疑问请及时联系宾客服务台。\n\n后续交通 码头出口有出租车候客区、网约车上客点，也可以提前预约接送服务。前往市区约需40-60分钟（视路况而定）。\n\n再会致辞 感谢您选择海洋光谱号，期待下次再会！", 
        images: ['https://images.unsplash.com/photo-1583417319070-4a69db38a482'] 
      }
    ],
    created_at: Time.current,
    updated_at: Time.current
  },
  # 地中海辉煌号 - 日韩航线
  {
    cruise_ship_id: bellissima.id,
    cruise_route_id: japan_korea_route.id,
    departure_date: Date.parse('2026-02-10'),
    return_date: Date.parse('2026-02-17'),
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
    departure_date: Date.parse('2026-02-20'),
    return_date: Date.parse('2026-02-26'),
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
    departure_date: Date.parse('2026-03-05'),
    return_date: Date.parse('2026-03-10'),
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
  {
    cruise_ship_id: aida_nova.id,
    cruise_route_id: southeast_asia_route.id,
    departure_date: Date.parse('2026-02-08'),
    return_date: Date.parse('2026-02-15'),
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
    departure_date: Date.parse('2026-02-18'),
    return_date: Date.parse('2026-02-24'),
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
  {
    cruise_ship_id: aida_nova.id,
    cruise_route_id: southeast_asia_route.id,
    departure_date: Date.parse('2026-03-01'),
    return_date: Date.parse('2026-03-09'),
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
    departure_date: Date.parse('2026-03-12'),
    return_date: Date.parse('2026-03-18'),
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
  }
]

CruiseSailing.insert_all(cruise_sailings_data)

# ==================== 舱房类型数据 ====================

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
    image_urls: [
      'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=600&h=400&fit=crop',
      'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=600&h=400&fit=crop'
    ],
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
    image_urls: ['https://images.unsplash.com/photo-1590490360182-c33d57733427?w=600&h=400&fit=crop'],
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
    image_urls: ['https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=600&h=400&fit=crop'],
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
    image_urls: [
      'https://images.unsplash.com/photo-1578683010236-d716f9a3f461?w=600&h=400&fit=crop',
      'https://images.unsplash.com/photo-1595576508898-0ad5c879a061?w=600&h=400&fit=crop'
    ],
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
    image_urls: ['https://images.unsplash.com/photo-1584132967334-10e028bd69f7?w=600&h=400&fit=crop'],
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
    image_urls: ['https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=600&h=400&fit=crop'],
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
    image_urls: [
      'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=600&h=400&fit=crop',
      'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=600&h=400&fit=crop'
    ],
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
    image_urls: ['https://images.unsplash.com/photo-1590490360182-c33d57733427?w=600&h=400&fit=crop'],
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
    image_urls: ['https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=600&h=400&fit=crop'],
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
    image_urls: [
      'https://images.unsplash.com/photo-1578683010236-d716f9a3f461?w=600&h=400&fit=crop',
      'https://images.unsplash.com/photo-1595576508898-0ad5c879a061?w=600&h=400&fit=crop'
    ],
    created_at: Time.current,
    updated_at: Time.current
  }
]

CabinType.insert_all(cabin_types_data)
puts "    ✓ 已加载 #{cabin_types_data.size} 种舱房类型"

# ==================== 商家数据 ====================
puts "  → 正在加载商家数据..."

travel_agencies_data = [
  {
    name: '皇家加勒比国际游轮旗舰店',
    rating: 4.9,
    is_verified: true,
    description: '皇家加勒比国际游轮官方旗舰店',
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    name: 'msc邮轮旗舰店',
    rating: 4.8,
    is_verified: true,
    description: '地中海邮轮官方旗舰店',
    created_at: Time.current,
    updated_at: Time.current
  }
]

TravelAgency.insert_all(travel_agencies_data)
puts "    ✓ 已加载 #{travel_agencies_data.size} 家商家"

# ==================== 商家产品数据 ====================
puts "  → 正在加载商家产品数据..."

# 获取所有航班
all_sailings = CruiseSailing.all.to_a

# 为每个航班的每种舱房类型创建产品
cruise_products_data = []

all_sailings.each do |sailing|
  ship = sailing.cruise_ship
  cabin_types = ship.cabin_types
  
  cabin_types.each do |cabin_type|
    # 根据舱房类型设置价格（基础价格 + 航线调整 + 舱只调整）
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
    
    final_price = (base_price * route_multiplier * ship_multiplier * duration_multiplier).round(1)
    
    # 随机选择商家
    merchant = ['msc邮轮旗舰店', '皇家加勒比国际游轮旗舰店'].sample
    
    cruise_products_data << {
      cruise_sailing_id: sailing.id,
      cabin_type_id: cabin_type.id,
      merchant_name: merchant,
      price_per_person: final_price,
      occupancy_requirement: 2,
      stock: rand(50..150),
      sales_count: rand(100..5000),
      is_refundable: [true, false].sample,
      requires_confirmation: false,
      status: 'on_sale',
      badge: ['品牌官方', '限时特价', '热销爆款', nil].sample,
      created_at: Time.current,
      updated_at: Time.current
    }
  end
end

CruiseProduct.insert_all(cruise_products_data)
puts "    ✓ 已加载 #{cruise_products_data.size} 个商家产品"

puts "✓ cruises_v1 数据包加载完成"
