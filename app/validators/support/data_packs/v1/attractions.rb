# frozen_string_literal: true

# 景点数据包 - 使用 insert_all 批量插入
# 包含景点、门票、景点内项目、一日游等数据

puts "正在加载景点数据包..."

# 清理现有数据
AttractionReview.destroy_all
ActivityOrder.destroy_all
TicketOrder.destroy_all
AttractionActivity.destroy_all
TicketSupplier.destroy_all
Ticket.destroy_all
Attraction.destroy_all

timestamp = Time.current

# ==================== 景点数据 ====================

attractions_data = [
  # ========== 深圳景点 (8个) ==========
  {
    name: "深圳欢乐港湾",
    slug: "shenzhen-happy-harbor",
    province: "广东省",
    city: "深圳",
    district: "宝安区",
    address: "深圳市宝安区海天路与宝华路交汇处",
    latitude: 22.563889,
    longitude: 113.862222,
    description: "欢乐港湾是深圳西部的滨海文化旅游新地标，集主题乐园、文化演艺、购物餐饮于一体。这里拥有全球最大的海上摩天轮，以及精彩的水幕灯光秀表演。",
    opening_hours: "10:00-22:00",
    phone: "0755-88888888",
    rating: 4.5,
    review_count: 1258,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "深圳世界之窗",
    slug: "shenzhen-window-of-the-world",
    province: "广东省",
    city: "深圳",
    district: "南山区",
    address: "深圳市南山区华侨城深南大道9037号",
    latitude: 22.537,
    longitude: 113.974,
    description: "汇集世界各地名胜古迹的微缩景观，一天游遍全球。含埃菲尔铁塔、金字塔、泰姬陵等130多个世界著名景点的缩影。",
    opening_hours: "09:00-22:30",
    phone: "0755-26608000",
    rating: 4.4,
    review_count: 3528,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "深圳欢乐谷",
    slug: "shenzhen-happy-valley",
    province: "广东省",
    city: "深圳",
    district: "南山区",
    address: "深圳市南山区侨城西路18号",
    latitude: 22.540,
    longitude: 113.980,
    description: "中国最佳主题乐园之一，拥有100多个游乐项目。含九大主题区，如西班牙广场、卡通城、冒险山、金矿镇等，适合全家游玩。",
    opening_hours: "09:30-21:00",
    phone: "0755-26949184",
    rating: 4.6,
    review_count: 4856,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "深圳东部华侨城",
    slug: "shenzhen-oct-east",
    province: "广东省",
    city: "深圳",
    district: "盐田区",
    address: "深圳市盐田区大梅沙东部华侨城",
    latitude: 22.596,
    longitude: 114.306,
    description: "集休闲度假、观光旅游、户外运动等于一体的大型综合性旅游度假区。含大侠谷、茶溪谷两大主题公园，还有云海谷高尔夫球场。",
    opening_hours: "09:30-17:30",
    phone: "0755-88889888",
    rating: 4.5,
    review_count: 2156,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "深圳野生动物园",
    slug: "shenzhen-safari-park",
    province: "广东省",
    city: "深圳",
    district: "南山区",
    address: "深圳市南山区西丽湖路4065号",
    latitude: 22.595,
    longitude: 113.949,
    description: "中国第一家放养式野生动物园，拥有300多种、近万只野生动物。可近距离观看狮子、老虎、长颈鹿等动物，还有精彩的动物表演。",
    opening_hours: "09:30-18:00",
    phone: "0755-26622892",
    rating: 4.3,
    review_count: 3256,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "深圳锦绣中华民俗村",
    slug: "shenzhen-splendid-china",
    province: "广东省",
    city: "深圳",
    district: "南山区",
    address: "深圳市南山区深南大道9003号",
    latitude: 22.537,
    longitude: 113.968,
    description: "展示中国传统文化和民族风情的主题公园。82个中国各地景区的缩影，以及56个民族的民俗文化表演，是了解中国文化的绝佳窗口。",
    opening_hours: "10:00-21:00",
    phone: "0755-26605626",
    rating: 4.2,
    review_count: 2856,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "深圳海上世界",
    slug: "shenzhen-sea-world",
    province: "广东省",
    city: "深圳",
    district: "南山区",
    address: "深圳市南山区蛇口望海路1128号",
    latitude: 22.487,
    longitude: 113.909,
    description: "以明华轮邮轮为中心的滨海文化旅游区，集购物、餐饮、娱乐为一体。夜景优美，是深圳年轻人休闲聚会的热门地点。",
    opening_hours: "全天开放",
    phone: "0755-26851777",
    rating: 4.4,
    review_count: 1958,
    is_free: true,  # 免费景点
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "深圳大梅沙海滨公园",
    slug: "shenzhen-dameisha-beach",
    province: "广东省",
    city: "深圳",
    district: "盐田区",
    address: "深圳市盐田区大梅沙盐梅路9号",
    latitude: 22.592,
    longitude: 114.315,
    description: "深圳最长的海滩，免费开放的公共海滨浴场。金色沙滩、碧蓝海水，是夏日消暑的好去处，也是观赏日出的绝佳地点。",
    opening_hours: "全天开放",
    phone: "0755-25036051",
    rating: 4.1,
    review_count: 4256,
    is_free: true,  # 免费景点
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },

  # ========== 上海景点 (7个) ==========
  {
    name: "上海迪士尼乐园",
    slug: "shanghai-disney",
    province: "上海市",
    city: "上海",
    district: "浦东新区",
    address: "上海市浦东新区川沙新镇上海迪士尼度假区",
    latitude: 31.145,
    longitude: 121.666,
    description: "中国大陆首座迪士尼主题乐园，拥有七大主题园区，包括米奇大街、奇想花园、梦幻世界、探险岛、宝藏湾、明日世界和迪士尼·皮克斯玩具总动员主题园区，适合全家游玩。",
    opening_hours: "09:00-21:00",
    phone: "021-31580000",
    rating: 4.7,
    review_count: 8520,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "上海海昌海洋公园",
    slug: "shanghai-haichang-ocean-park",
    province: "上海市",
    city: "上海",
    district: "浦东新区",
    address: "上海市浦东新区南汇新城银飞路166号",
    latitude: 31.016,
    longitude: 121.921,
    description: "大型海洋主题公园，拥有五大主题区和十余项游乐设施。可观赏白鲸、海豚、企鹅等海洋动物，还有精彩的海洋动物表演。",
    opening_hours: "09:00-17:30",
    phone: "021-61674888",
    rating: 4.5,
    review_count: 3256,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "上海欢乐谷",
    slug: "shanghai-happy-valley",
    province: "上海市",
    city: "上海",
    district: "松江区",
    address: "上海市松江区林湖路888号",
    latitude: 31.069,
    longitude: 121.174,
    description: "华东地区最大的主题乐园之一，拥有100多个游乐项目。七大主题区域包括阳光港、欢乐时光、上海滩等，刺激与欢乐并存。",
    opening_hours: "10:00-18:00",
    phone: "021-33552222",
    rating: 4.4,
    review_count: 4156,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "上海野生动物园",
    slug: "shanghai-wild-animal-park",
    province: "上海市",
    city: "上海",
    district: "浦东新区",
    address: "上海市浦东新区南六公路178号",
    latitude: 31.052,
    longitude: 121.703,
    description: "国家5A级景区，中国首座国家级野生动物园。拥有200余种、上万只动物，可乘车游览猛兽区，近距离观看狮虎熊豹等动物。",
    opening_hours: "08:30-17:00",
    phone: "021-58036000",
    rating: 4.5,
    review_count: 5256,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "上海东方明珠",
    slug: "shanghai-oriental-pearl-tower",
    province: "上海市",
    city: "上海",
    district: "浦东新区",
    address: "上海市浦东新区世纪大道1号",
    latitude: 31.240,
    longitude: 121.499,
    description: "上海地标建筑，高468米的广播电视塔。含观光层、旋转餐厅、太空舱等，可俯瞰黄浦江两岸美景，夜景尤为壮观。",
    opening_hours: "08:00-21:30",
    phone: "021-58791888",
    rating: 4.6,
    review_count: 7856,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "上海长风海洋世界",
    slug: "shanghai-changfeng-ocean-world",
    province: "上海市",
    city: "上海",
    district: "普陀区",
    address: "上海市普陀区大渡河路451号",
    latitude: 31.252,
    longitude: 121.413,
    description: "水族馆与海洋动物表演馆相结合的综合性海洋主题公园。拥有300余种、15000余尾海洋水生动物，白鲸表演最受欢迎。",
    opening_hours: "08:30-17:00",
    phone: "021-62200368",
    rating: 4.3,
    review_count: 2156,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "上海杜莎夫人蜡像馆",
    slug: "shanghai-madame-tussauds",
    province: "上海市",
    city: "上海",
    district: "黄浦区",
    address: "上海市黄浦区南京西路2-68号新世界商厦10楼",
    latitude: 31.234,
    longitude: 121.474,
    description: "全球知名的蜡像馆，汇集全球名人明星蜡像。可与姚明、成龙、泰勒·斯威夫特等明星蜡像合影，互动体验丰富。",
    opening_hours: "10:00-21:00",
    phone: "021-63587878",
    rating: 4.2,
    review_count: 1856,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },

  # ========== 北京景点 (7个) ==========
  {
    name: "北京环球影城",
    slug: "beijing-universal",
    province: "北京市",
    city: "北京",
    district: "通州区",
    address: "北京市通州区京哈高速与东六环路交汇处",
    latitude: 39.876,
    longitude: 116.704,
    description: "全球最大的环球影城主题公园，七大主题景区带你进入电影世界。包括哈利·波特的魔法世界、变形金刚基地、小黄人乐园、侏罗纪世界努布拉岛、好莱坞、未来水世界和功夫熊猫盖世之地。",
    opening_hours: "09:00-20:00",
    phone: "010-67778899",
    rating: 4.6,
    review_count: 6352,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "北京欢乐谷",
    slug: "beijing-happy-valley",
    province: "北京市",
    city: "北京",
    district: "朝阳区",
    address: "北京市朝阳区东四环小武基北路",
    latitude: 39.853,
    longitude: 116.502,
    description: "华北地区最大的主题公园，拥有120余项游乐设施。包括峡湾森林、亚特兰蒂斯、失落玛雅、香格里拉等七大主题区，适合全家游玩。",
    opening_hours: "10:00-18:00",
    phone: "010-67389898",
    rating: 4.5,
    review_count: 4256,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "北京野生动物园",
    slug: "beijing-wildlife-park",
    province: "北京市",
    city: "北京",
    district: "大兴区",
    address: "北京市大兴区榆垡镇万亩森林之中",
    latitude: 39.580,
    longitude: 116.338,
    description: "国家4A级景区，散养、圈养相结合的大型野生动物园。拥有200余种、10000余只动物，可自驾游览猛兽区，体验与动物零距离接触。",
    opening_hours: "08:30-17:30",
    phone: "010-89216666",
    rating: 4.4,
    review_count: 3856,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "北京海洋馆",
    slug: "beijing-aquarium",
    province: "北京市",
    city: "北京",
    district: "海淀区",
    address: "北京市海淀区高粱桥斜街乙18号",
    latitude: 39.942,
    longitude: 116.338,
    description: "亚洲最大的内陆水族馆，位于北京动物园内。拥有海洋生物千余种、数万尾，白鲸、海豚、海狮表演精彩纷呈。",
    opening_hours: "09:00-17:00",
    phone: "010-68714695",
    rating: 4.3,
    review_count: 2956,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "北京石景山游乐园",
    slug: "beijing-shijingshan-amusement-park",
    province: "北京市",
    city: "北京",
    district: "石景山区",
    address: "北京市石景山区石景山路25号",
    latitude: 39.914,
    longitude: 116.195,
    description: "北京第一座现代化大型游乐园，拥有原子滑车、大观览车、勇敢者转盘等50余项游乐设施。灰姑娘城堡是标志性建筑。",
    opening_hours: "09:00-17:30",
    phone: "010-68874060",
    rating: 4.2,
    review_count: 1856,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "北京世界公园",
    slug: "beijing-world-park",
    province: "北京市",
    city: "北京",
    district: "丰台区",
    address: "北京市丰台区花乡丰葆路158号",
    latitude: 39.809,
    longitude: 116.275,
    description: "汇集世界各国名胜古迹的微缩景观公园。含100多个世界著名景观的复制品，如埃菲尔铁塔、金字塔、自由女神像等。",
    opening_hours: "08:00-17:30",
    phone: "010-83613681",
    rating: 4.1,
    review_count: 1256,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "北京杜莎夫人蜡像馆",
    slug: "beijing-madame-tussauds",
    province: "北京市",
    city: "北京",
    district: "朝阳区",
    address: "北京市朝阳区建国门外大街1号国贸商城3层",
    latitude: 39.908,
    longitude: 116.460,
    description: "全球第六座杜莎夫人蜡像馆，展示众多名人明星蜡像。可与姚明、刘德华、奥巴马等蜡像近距离互动拍照。",
    opening_hours: "10:00-20:00",
    phone: "010-65051118",
    rating: 4.2,
    review_count: 1556,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },

  # ========== 广州景点 (6个) ==========
  {
    name: "广州长隆欢乐世界",
    slug: "guangzhou-chimelong",
    province: "广东省",
    city: "广州",
    district: "番禺区",
    address: "广州市番禺区汉溪大道东与长隆地铁大道交汇处",
    latitude: 23.004,
    longitude: 113.329,
    description: "华南地区最大的主题乐园，拥有70余套游乐设施，刺激与欢乐并存。园内有垂直过山车、十环过山车、摩托过山车等世界级游乐设施，还有精彩的国际大马戏表演。",
    opening_hours: "10:00-18:00",
    phone: "020-84783838",
    rating: 4.4,
    review_count: 4235,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "广州长隆野生动物世界",
    slug: "guangzhou-chimelong-safari",
    province: "广东省",
    city: "广州",
    district: "番禺区",
    address: "广州市番禺区大石镇105国道大石段593号",
    latitude: 23.005,
    longitude: 113.332,
    description: "世界级野生动物园，拥有500余种、20000余只动物。可自驾游览，近距离观看狮子、老虎、长颈鹿等动物，还有珍稀的熊猫三胞胎。",
    opening_hours: "09:30-18:00",
    phone: "020-84783838",
    rating: 4.6,
    review_count: 6856,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "广州长隆水上乐园",
    slug: "guangzhou-chimelong-water-park",
    province: "广东省",
    city: "广州",
    district: "番禺区",
    address: "广州市番禺区迎宾路长隆旅游度假区内",
    latitude: 23.003,
    longitude: 113.331,
    description: "亚洲最大的水上乐园，连续多年获得全球主题娱乐协会颁发的杰出成就奖。拥有巨蟒、喷射滑道、离心滑道等众多刺激水上项目。",
    opening_hours: "10:00-22:00 (夏季)",
    phone: "020-84783838",
    rating: 4.5,
    review_count: 5256,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "广州塔",
    slug: "guangzhou-tower",
    province: "广东省",
    city: "广州",
    district: "海珠区",
    address: "广州市海珠区阅江西路222号",
    latitude: 23.106,
    longitude: 113.320,
    description: "广州新地标，昵称'小蛮腰'，塔高600米。含观光层、旋转餐厅、摩天轮、高空跳楼机等项目，可360度俯瞰广州全景。",
    opening_hours: "09:30-22:30",
    phone: "020-89338222",
    rating: 4.5,
    review_count: 8256,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "广州海洋馆",
    slug: "guangzhou-ocean-world",
    province: "广东省",
    city: "广州",
    district: "越秀区",
    address: "广州市越秀区先烈中路120号动物园内",
    latitude: 23.149,
    longitude: 113.302,
    description: "华南地区最大的海洋馆之一，拥有200余种海洋生物。可观赏海豚、海狮、海豹表演，还有神秘的海底隧道体验。",
    opening_hours: "09:00-17:30",
    phone: "020-38377572",
    rating: 4.3,
    review_count: 2856,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "广州正佳极地海洋世界",
    slug: "guangzhou-grandview-aquarium",
    province: "广东省",
    city: "广州",
    district: "天河区",
    address: "广州市天河区天河路228号正佳广场西侧2-3层",
    latitude: 23.134,
    longitude: 113.328,
    description: "都市中心的海洋王国，拥有500余种海洋生物。可观赏北极熊、企鹅、白鲸等极地动物，还有美人鱼表演和水下芭蕾。",
    opening_hours: "10:00-21:00",
    phone: "020-28332888",
    rating: 4.4,
    review_count: 3456,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },

  # ========== 杭州景点 (6个) ==========
  {
    name: "杭州宋城",
    slug: "hangzhou-songcheng",
    province: "浙江省",
    city: "杭州",
    district: "西湖区",
    address: "浙江省杭州市西湖区之江路148号",
    latitude: 30.195,
    longitude: 120.100,
    description: "给我一天，还你千年。大型主题公园，再现宋代繁华。园内有宋城千古情演出、清明上河图、步步惊心鬼屋等特色项目，是体验宋代文化的绝佳去处。",
    opening_hours: "10:00-21:00",
    phone: "0571-87313101",
    rating: 4.3,
    review_count: 3128,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "杭州烂苹果乐园",
    slug: "hangzhou-rotten-apple-paradise",
    province: "浙江省",
    city: "杭州",
    district: "萧山区",
    address: "杭州市萧山区风情大道2555号",
    latitude: 30.216,
    longitude: 120.285,
    description: "中国最大的室内高科技亲子乐园，拥有70余项高科技互动项目。魔法丛林、海底世界、糖果小镇等主题区域，适合亲子游玩。",
    opening_hours: "09:00-17:00",
    phone: "0571-82899999",
    rating: 4.2,
    review_count: 2456,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "杭州极地海洋世界",
    slug: "hangzhou-polar-ocean-park",
    province: "浙江省",
    city: "杭州",
    district: "萧山区",
    address: "杭州市萧山区湘湖路777号",
    latitude: 30.183,
    longitude: 120.207,
    description: "华东地区最大的海洋主题公园，拥有北极熊、企鹅、白鲸等200余种海洋生物。极地动物馆、海洋剧场等场馆精彩纷呈。",
    opening_hours: "09:00-17:00",
    phone: "0571-83859999",
    rating: 4.4,
    review_count: 3856,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "杭州野生动物世界",
    slug: "hangzhou-safari-park",
    province: "浙江省",
    city: "杭州",
    district: "富阳区",
    address: "杭州市富阳区杭富路九龙大道1号",
    latitude: 30.074,
    longitude: 119.985,
    description: "华东地区规模最大的野生动物世界，拥有200余种、近万只动物。可自驾游览猛兽区，近距离观看狮虎豹等动物，还有精彩的动物表演。",
    opening_hours: "09:30-17:00",
    phone: "0571-23240000",
    rating: 4.5,
    review_count: 4256,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "杭州Hello Kitty乐园",
    slug: "hangzhou-hello-kitty-park",
    province: "浙江省",
    city: "杭州",
    district: "萧山区",
    address: "杭州市萧山区风情大道2555号",
    latitude: 30.217,
    longitude: 120.286,
    description: "全球第二座Hello Kitty主题乐园，少女心爆棚的梦幻世界。含友谊广场、欢乐港湾、音之村、精灵森林等六大主题区域。",
    opening_hours: "09:30-17:30",
    phone: "0571-82737777",
    rating: 4.3,
    review_count: 2656,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "杭州乐园",
    slug: "hangzhou-amusement-park",
    province: "浙江省",
    city: "杭州",
    district: "萧山区",
    address: "杭州市萧山区风情大道2555号",
    latitude: 30.215,
    longitude: 120.284,
    description: "长三角地区著名的综合性主题公园，拥有过山车、激流勇进、大摆锤等40余项游乐设施。含玛雅部落、失落丛林等主题区域。",
    opening_hours: "09:00-17:00",
    phone: "0571-82898888",
    rating: 4.4,
    review_count: 3556,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },

  # ========== 成都景点 (6个) ==========
  {
    name: "成都欢乐谷",
    slug: "chengdu-happy-valley",
    province: "四川省",
    city: "成都",
    district: "金牛区",
    address: "四川省成都市金牛区西华大道16号",
    latitude: 30.717,
    longitude: 104.006,
    description: "西南地区大型现代主题乐园，拥有阳光港、欢乐时光、加勒比旋风等八大主题区域。园内有雪域雄鹰、天地双雄、飞行岛等30余项游乐设施。",
    opening_hours: "09:30-18:00",
    phone: "028-87512666",
    rating: 4.4,
    review_count: 2856,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "成都大熊猫繁育研究基地",
    slug: "chengdu-panda-base",
    province: "四川省",
    city: "成都",
    district: "成华区",
    address: "成都市成华区外北三环熊猫大道1375号",
    latitude: 30.735,
    longitude: 104.150,
    description: "世界著名的大熊猫迁地保护基地，拥有大熊猫、小熊猫、黑颈鹤等珍稀动物。可近距离观看憨态可掬的大熊猫，了解熊猫保护知识。",
    opening_hours: "07:30-18:00",
    phone: "028-83510033",
    rating: 4.7,
    review_count: 12856,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "成都海昌极地海洋公园",
    slug: "chengdu-haichang-ocean-park",
    province: "四川省",
    city: "成都",
    district: "双流区",
    address: "成都市双流区天府大道南段1375号",
    latitude: 30.548,
    longitude: 103.996,
    description: "西南地区最大的海洋主题公园，拥有北极熊、企鹅、白鲸等300余种海洋生物。海豚表演、海狮表演精彩纷呈。",
    opening_hours: "09:30-18:00",
    phone: "028-68718888",
    rating: 4.5,
    review_count: 4256,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "成都国色天乡乐园",
    slug: "chengdu-guose-tianxiang",
    province: "四川省",
    city: "成都",
    district: "温江区",
    address: "成都市温江区万春镇国色天乡路168号",
    latitude: 30.682,
    longitude: 103.826,
    description: "童话城堡主题的大型游乐园，拥有过山车、摩天轮、激流勇进等50余项游乐设施。陆地乐园与水上乐园相结合。",
    opening_hours: "09:30-18:00",
    phone: "028-82611888",
    rating: 4.3,
    review_count: 2456,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "成都植物园",
    slug: "chengdu-botanical-garden",
    province: "四川省",
    city: "成都",
    district: "金牛区",
    address: "成都市金牛区天回镇蓉都大道1116号",
    latitude: 30.742,
    longitude: 104.068,
    description: "西南地区最大的植物园，拥有8000余种植物。春季赏樱花、郁金香，夏季观荷花、睡莲，秋季看银杏、红枫，四季皆宜。",
    opening_hours: "06:00-22:00",
    phone: "028-83510120",
    rating: 4.2,
    review_count: 1856,
    is_free: true,  # 免费景点
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "成都浩海立方海洋馆",
    slug: "chengdu-haocube-aquarium",
    province: "四川省",
    city: "成都",
    district: "双流区",
    address: "成都市双流区天府大道南段2039号",
    latitude: 30.549,
    longitude: 103.997,
    description: "西南首家海洋馆，拥有海洋生物300余种。海底隧道、触摸池、水母宫等特色场馆，还有精彩的美人鱼表演。",
    opening_hours: "10:00-18:00",
    phone: "028-85911666",
    rating: 4.3,
    review_count: 2156,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
]

Attraction.insert_all(attractions_data)
puts "✓ 已批量创建 #{Attraction.count} 个景点"

# 获取景点ID映射
attractions_map = Attraction.pluck(:slug, :id).to_h

# ==================== 门票数据 ====================

tickets_data = []

# 为每个景点创建门票（免费景点除外）
attractions_data.each do |attraction_info|
  next if attraction_info[:is_free]  # 跳过免费景点
  
  slug = attraction_info[:slug]
  name = attraction_info[:name]
  attraction_id = attractions_map[slug]
  
  # 根据景点类型设置基础价格
  base_price = case slug
  when /disney|universal|chimelong-safari/ then 450
  when /happy-valley|ocean|chimelong|oct-east/ then 250
  when /songcheng|window|safari/ then 200
  when /panda/ then 55
  when /tower|madame/ then 150
  else 120
  end
  
  # 成人票
  tickets_data << {
    attraction_id: attraction_id,
    name: "#{name}成人票",
    ticket_type: "adult",
    requirements: "适用于18-59周岁成人",
    current_price: base_price,
    original_price: (base_price * 1.2).round,
    stock: -1,
    validity_days: 1,
    refund_policy: "未使用可随时退款",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
  
  # 儿童票
  tickets_data << {
    attraction_id: attraction_id,
    name: "#{name}儿童票",
    ticket_type: "child",
    requirements: "适用于3-17周岁儿童或1.2-1.5米儿童",
    current_price: (base_price * 0.7).round,
    original_price: (base_price * 0.8).round,
    stock: -1,
    validity_days: 1,
    refund_policy: "未使用可随时退款",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
  
  # 大型乐园额外添加家庭套票
  if slug =~ /disney|universal|happy-valley|chimelong/
    tickets_data << {
      attraction_id: attraction_id,
      name: "#{name}家庭套票",
      ticket_type: "family",
      requirements: "2成人+1儿童",
      current_price: (base_price * 2.3).round,
      original_price: (base_price * 2.7).round,
      stock: -1,
      validity_days: 1,
      refund_policy: "需提前24小时申请退款",
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    }
  end
end

Ticket.insert_all(tickets_data) if tickets_data.any?
puts "✓ 已批量创建 #{Ticket.count} 张门票"

# ==================== 供应商数据 ====================
puts "\n🏢 批量创建供应商..."

suppliers_data = [
  {
    name: "旅游景区乐园旗舰店",
    supplier_type: "official",
    rating: 4.8,
    sales_count: 3800,
    description: "7×24小时官网客服·极速响应·售后无忧",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "票圈小叮当旅游专营店",
    supplier_type: "agent",
    rating: 4.6,
    sales_count: 2200,
    description: "随时全额退 无需取票",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "深圳木子花开旅游专营店",
    supplier_type: "agent",
    rating: 4.5,
    sales_count: 3000,
    description: "条件退 无需取票",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "重庆齐旅通旅游专营店",
    supplier_type: "agent",
    rating: 4.3,
    sales_count: 1700,
    description: "随时全额退 无需取票",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
]

Supplier.insert_all(suppliers_data)
puts "✓ 已批量创建 #{Supplier.count} 个供应商"

# 获取供应商ID映射
suppliers_map = Supplier.pluck(:name, :id).to_h

# ==================== 门票供应商关联数据 ====================
puts "\n🔗 批量创建门票供应商关联..."

ticket_suppliers_data = []

# 为每个门票创建多个供应商选项
Ticket.includes(:attraction).find_each do |ticket|
  base_price = ticket.current_price
  
  # 供应商1：官方旗舰店（最贵但服务最好）
  ticket_suppliers_data << {
    ticket_id: ticket.id,
    supplier_id: suppliers_map["旅游景区乐园旗舰店"],
    current_price: base_price,
    original_price: (base_price * 1.2).round,
    stock: -1,
    discount_info: "度假优惠",
    sales_count: rand(300..500),
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
  
  # 供应商2：票圈（性价比高）
  ticket_suppliers_data << {
    ticket_id: ticket.id,
    supplier_id: suppliers_map["票圈小叮当旅游专营店"],
    current_price: (base_price * 0.95).round,
    original_price: (base_price * 1.1).round,
    stock: -1,
    discount_info: "1张券",
    sales_count: rand(200..300),
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
  
  # 供应商3：木子花开（价格适中）
  ticket_suppliers_data << {
    ticket_id: ticket.id,
    supplier_id: suppliers_map["深圳木子花开旅游专营店"],
    current_price: (base_price * 1.05).round,
    original_price: (base_price * 1.25).round,
    stock: -1,
    discount_info: nil,
    sales_count: rand(300..400),
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
  
  # 供应商4：齐旅通（价格最低）
  ticket_suppliers_data << {
    ticket_id: ticket.id,
    supplier_id: suppliers_map["重庆齐旅通旅游专营店"],
    current_price: (base_price * 0.88).round,
    original_price: base_price,
    stock: -1,
    discount_info: nil,
    sales_count: rand(100..200),
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
end

TicketSupplier.insert_all(ticket_suppliers_data) if ticket_suppliers_data.any?
puts "✓ 已批量创建 #{TicketSupplier.count} 条门票供应商关联"

# ==================== 景点内项目数据（仅大型主题乐园）====================
puts "\n🎢 批量创建景点内项目（仅大型主题乐园）..."

attraction_activities_data = []

# 定义需要添加景点内项目的大型主题乐园
theme_park_activities = {
  "shanghai-disney" => [
    { name: "创极速光轮", activity_type: "ride", description: "《创：战纪》主题过山车，极速飞驰体验", current_price: 0, original_price: 0, sales_count: 0 },
    { name: "七个小矮人矿山车", activity_type: "ride", description: "梦幻世界经典过山车", current_price: 0, original_price: 0, sales_count: 0 },
    { name: "加勒比海盗沉落宝藏之战", activity_type: "ride", description: "沉浸式海盗冒险", current_price: 0, original_price: 0, sales_count: 0 },
    { name: "冰雪奇缘欢唱盛会", activity_type: "show", description: "与艾莎、安娜一起欢唱", current_price: 0, original_price: 0, sales_count: 0 },
    { name: "迪士尼魔法照相馆", activity_type: "photo_service", description: "与米奇米妮合影留念", current_price: 88, original_price: 120, sales_count: 256 }
  ],
  "beijing-universal" => [
    { name: "哈利·波特与禁忌之旅", activity_type: "ride", description: "魔法世界沉浸式冒险", current_price: 0, original_price: 0, sales_count: 0 },
    { name: "变形金刚3D骑行", activity_type: "ride", description: "与擎天柱并肩作战", current_price: 0, original_price: 0, sales_count: 0 },
    { name: "侏罗纪世界大冒险", activity_type: "ride", description: "激流勇进遇见恐龙", current_price: 0, original_price: 0, sales_count: 0 },
    { name: "未来水世界", activity_type: "show", description: "惊险刺激的特技表演", current_price: 0, original_price: 0, sales_count: 0 },
    { name: "哈利·波特魔法袍", activity_type: "experience", description: "魔法世界定制魔法袍", current_price: 299, original_price: 399, sales_count: 158 }
  ],
  "shenzhen-happy-valley" => [
    { name: "雪域雄鹰", activity_type: "ride", description: "世界最高落差悬挂过山车", current_price: 0, original_price: 0, sales_count: 0 },
    { name: "完美风暴", activity_type: "ride", description: "高速旋转的飞行岛", current_price: 0, original_price: 0, sales_count: 0 },
    { name: "激流勇进", activity_type: "ride", description: "高空俯冲水上冒险", current_price: 0, original_price: 0, sales_count: 0 },
    { name: "魔幻剧场", activity_type: "show", description: "大型魔术表演", current_price: 0, original_price: 0, sales_count: 0 }
  ],
  "guangzhou-chimelong" => [
    { name: "十环过山车", activity_type: "ride", description: "世界第二座十环过山车", current_price: 0, original_price: 0, sales_count: 0 },
    { name: "垂直过山车", activity_type: "ride", description: "90度垂直俯冲", current_price: 0, original_price: 0, sales_count: 0 },
    { name: "摩托过山车", activity_type: "ride", description: "摩托车式过山车", current_price: 0, original_price: 0, sales_count: 0 },
    { name: "长隆国际大马戏", activity_type: "show", description: "世界顶级马戏表演", current_price: 380, original_price: 480, sales_count: 426 }
  ]
}

theme_park_activities.each do |slug, activities|
  attraction_id = attractions_map[slug]
  next unless attraction_id
  
  activities.each do |activity|
    attraction_activities_data << {
      attraction_id: attraction_id,
      name: activity[:name],
      activity_type: activity[:activity_type],
      description: activity[:description],
      current_price: activity[:current_price],
      original_price: activity[:original_price],
      stock: -1,
      sales_count: activity[:sales_count],
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    }
  end
end

AttractionActivity.insert_all(attraction_activities_data) if attraction_activities_data.any?
puts "✓ 已批量创建 #{AttractionActivity.count} 个景点内项目"

# ==================== 一日游数据 ====================
puts "\n🚌 批量创建一日游产品..."

# 确保有旅行社
demo_agency = TravelAgency.find_or_create_by(name: "深圳市携程国际旅行社") do |a|
  a.rating = 4.8
  a.description = "专业旅游服务，品质保障"
end

# 为热门景点创建一日游产品
day_tour_products = [
  {
    title: "深圳欢乐谷+世界之窗一日游",
    destination: "深圳",
    attraction_slugs: ["shenzhen-happy-valley", "shenzhen-window-of-the-world"],
    price: 388,
    highlights: ["含两大景点门票", "全程导游讲解", "赠送午餐"],
    tags: ["亲子游", "家庭出游", "纯玩无购物"]
  },
  {
    title: "上海迪士尼乐园纯玩一日游",
    destination: "上海",
    attraction_slugs: ["shanghai-disney"],
    price: 599,
    highlights: ["市区酒店接送", "含门票免排队", "赠送迪士尼餐券"],
    tags: ["亲子游", "上门接送", "含门票"]
  },
  {
    title: "北京环球影城VIP一日游",
    destination: "北京",
    attraction_slugs: ["beijing-universal"],
    price: 799,
    highlights: ["VIP快速通道", "全程专车接送", "含门票和餐食"],
    tags: ["家庭出游", "上门接送", "无自费"]
  },
  {
    title: "广州长隆野生动物世界+欢乐世界一日游",
    destination: "广州",
    attraction_slugs: ["guangzhou-chimelong-safari", "guangzhou-chimelong"],
    price: 458,
    highlights: ["两大园区联票", "近距离观看动物", "刺激游乐设施"],
    tags: ["亲子游", "含门票", "纯玩无购物"]
  },
  {
    title: "成都大熊猫基地+市区精华一日游",
    destination: "成都",
    attraction_slugs: ["chengdu-panda-base"],
    price: 218,
    highlights: ["早晨看熊猫最活跃", "宽窄巷子自由活动", "品尝地道川菜"],
    tags: ["深度体验", "美食", "小团出行"]
  }
]

tour_products_data = []

day_tour_products.each do |tour_info|
  # 为一日游关联主景点
  main_attraction_id = attractions_map[tour_info[:attraction_slugs].first]
  
  tour_products_data << {
    travel_agency_id: demo_agency.id,
    attraction_id: main_attraction_id,
    title: tour_info[:title],
    subtitle: "品质保障 放心出游",
    tour_category: "group_tour",
    travel_type: "跟团游",
    destination: tour_info[:destination],
    duration: 1,
    departure_city: tour_info[:destination],
    price: tour_info[:price],
    original_price: (tour_info[:price] * 1.2).round,
    rating: [4.5, 4.6, 4.7, 4.8].sample,
    rating_desc: "#{rand(100..500)}条评价",
    highlights: tour_info[:highlights].to_json,
    tags: tour_info[:tags].to_json,
    sales_count: rand(50..300),
    badge: "一日游",
    departure_label: "每日发团",
    image_url: "https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800",
    is_featured: true,
    display_order: rand(1..50),
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
end

TourGroupProduct.insert_all(tour_products_data) if tour_products_data.any?
puts "✓ 已批量创建 #{TourGroupProduct.where(tour_category: 'group_tour', duration: 1).count} 个一日游产品"

# ==================== 评价数据 ====================
puts "\n⭐ 批量创建评价..."

# 创建多个真实用户
real_users_data = [
  { email: "zhangwei@163.com", name: "张伟" },
  { email: "liping@qq.com", name: "李婷" },
  { email: "wanghao@gmail.com", name: "王昊" },
  { email: "liujing@126.com", name: "刘静" },
  { email: "chenlei@sina.com", name: "陈雷" },
  { email: "yangmei@hotmail.com", name: "杨梅" },
  { email: "zhoujie@outlook.com", name: "周杰" },
  { email: "wuxin@163.com", name: "吴鑫" },
  { email: "zhengmin@qq.com", name: "郑敏" },
  { email: "sunxiaoyu@gmail.com", name: "孙小雨" }
]

real_users = []
real_users_data.each do |user_data|
  user = User.find_or_create_by(email: user_data[:email]) do |u|
    u.name = user_data[:name]
    u.password_digest = BCrypt::Password.create("password123")
  end
  real_users << user
end

puts "✓ 已创建 #{real_users.count} 个用户"

review_comments = [
  { rating: 5, comment: "景点太棒了！项目丰富，玩了一整天都不够，强烈推荐！" },
  { rating: 5, comment: "带孩子来的，孩子玩得非常开心，设施很安全，服务也很好。" },
  { rating: 4, comment: "整体体验不错，就是人有点多，排队时间较长。" },
  { rating: 5, comment: "值得一去！环境很好，工作人员态度也很友善。" },
  { rating: 4, comment: "门票价格稍贵，但玩下来觉得还是物有所值的。" },
  { rating: 5, comment: "和朋友一起来的，大家都玩得很尽兴，拍了很多美照！" },
  { rating: 4, comment: "项目很刺激，适合年轻人，带老人的话要注意选择合适的项目。" },
  { rating: 5, comment: "园区很大，建议提前规划路线，可以下载官方APP查看项目排队情况。" },
  { rating: 5, comment: "性价比很高，非常值得一去，下次还会再来！" },
  { rating: 4, comment: "交通很方便，地铁直达。园区内餐饮选择很多。" }
]

reviews_data = []
Attraction.find_each do |attraction|
  # 每个景点创建8-15条评价，用不同用户
  review_comments.sample(rand(8..15)).each do |review|
    reviews_data << {
      attraction_id: attraction.id,
      user_id: real_users.sample.id,  # 从真实用户中随机选择
      rating: review[:rating],
      comment: review[:comment],
      helpful_count: rand(0..50),
      data_version: 0,
      created_at: timestamp - rand(1..90).days,
      updated_at: timestamp - rand(1..90).days
    }
  end
end

AttractionReview.insert_all(reviews_data) if reviews_data.any?
puts "✓ 已批量创建 #{AttractionReview.count} 条评价"

# 更新景点统计数据（rating 和 review_count）
puts "\n🔄 更新景点统计数据..."
Attraction.find_each do |attraction|
  reviews = AttractionReview.where(attraction_id: attraction.id)
  if reviews.any?
    attraction.update_columns(
      rating: reviews.average(:rating)&.round(1) || 0,
      review_count: reviews.count
    )
  end
end

puts "\n" + "="*50
puts "✅ 景点数据包加载完成！"
puts "="*50
puts "📊 数据统计："
puts "  - 景点数量: #{Attraction.count}"
puts "  - 免费景点: #{Attraction.where(is_free: true).count}"
puts "  - 门票数量: #{Ticket.count}"
puts "  - 供应商数量: #{Supplier.count}"
puts "  - 门票供应商关联: #{TicketSupplier.count}"
puts "  - 景点内项目: #{AttractionActivity.count}"
puts "  - 一日游产品: #{TourGroupProduct.where(duration: 1).count}"
puts "  - 评价数量: #{AttractionReview.count}"
puts "\n📍 各城市景点数量："
Attraction.group(:city).count.each do |city, count|
  free_count = Attraction.where(city: city, is_free: true).count
  paid_count = count - free_count
  puts "  - #{city}: #{count}个景点（收费#{paid_count}个，免费#{free_count}个）"
end
puts "="*50
