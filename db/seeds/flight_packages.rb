# Flight Packages (机票次卡) Seed Data
puts "Creating flight packages..."

FlightPackage.destroy_all

packages = [
  {
    title: "AG超玩会联名",
    subtitle: "国内·单人单程",
    price: 298,
    original_price: 498,
    discount_label: "超低价",
    badge_text: "1次卡",
    badge_color: "#FF9800",
    destination: "全国",
    image_url: "https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=400",
    valid_days: 365,
    description: "AG超玩会联名机票次卡，全国航线任选，有效期1年",
    features: ["全国航线通用", "有效期1年", "不限航司", "可退可改"],
    status: "active"
  },
  {
    title: "24节气卡小寒卡",
    subtitle: "国内·单人单程",
    price: 299,
    original_price: 599,
    discount_label: "超低价",
    badge_text: "1次卡",
    badge_color: "#03A9F4",
    destination: "全国",
    image_url: "https://images.unsplash.com/photo-1436491865332-7a61a109cc05?w=400",
    valid_days: 365,
    description: "24节气主题机票次卡，冬季出行专属优惠",
    features: ["全国航线通用", "有效期1年", "不限航司", "节日特惠"],
    status: "active"
  },
  {
    title: "国际机票盲盒",
    subtitle: "666元飞全球",
    price: 666,
    original_price: 2999,
    discount_label: "每日秒杀",
    badge_text: "盲盒",
    badge_color: "#F44336",
    destination: "全球",
    image_url: "https://images.unsplash.com/photo-1488085061387-422e29b40080?w=400",
    valid_days: 180,
    description: "国际机票盲盒，666元飞全球，16点开抢",
    features: ["全球航线", "惊喜目的地", "超值优惠", "有效期半年"],
    status: "active"
  },
  {
    title: "去昆明专线",
    subtitle: "国内热门航线",
    price: 399,
    original_price: 899,
    discount_label: "5折起",
    badge_text: "直播",
    badge_color: "#E91E63",
    destination: "昆明",
    image_url: "https://images.unsplash.com/photo-1570168007204-dfb528c6958f?w=400",
    valid_days: 365,
    description: "昆明专线机票次卡，四季如春好去处",
    features: ["昆明专线", "全年有效", "多航班可选", "旺季适用"],
    status: "active"
  },
  {
    title: "去三亚海岛游",
    subtitle: "阳光沙滩海浪",
    price: 499,
    original_price: 1299,
    discount_label: "新品情报站",
    badge_text: "2次卡",
    badge_color: "#00BCD4",
    destination: "三亚",
    image_url: "https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=400",
    valid_days: 365,
    description: "三亚海岛游机票次卡，往返2次，全年无休",
    features: ["往返2次", "全年有效", "含税费", "度假首选"],
    status: "active"
  },
  {
    title: "去成都吃火锅",
    subtitle: "美食之都专线",
    price: 299,
    original_price: 799,
    discount_label: "限时特惠",
    badge_text: "1次卡",
    badge_color: "#FF5722",
    destination: "成都",
    image_url: "https://images.unsplash.com/photo-1561814053-c52db5e102e2?w=400",
    valid_days: 365,
    description: "成都美食之旅机票次卡，品尝正宗川菜",
    features: ["成都专线", "美食推荐", "有效期1年", "多航班"],
    status: "active"
  }
]

packages.each do |package_data|
  FlightPackage.create!(package_data)
  print "."
end

puts "\n✅ Created #{FlightPackage.count} flight packages"
