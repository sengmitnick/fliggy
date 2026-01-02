# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# IMPORTANT: Do NOT add Administrator data here!
# Administrator accounts should be created manually by user.
# This seeds file is only for application data (products, categories, etc.)
#
require 'open-uri'

# Write your seed data here

# ==================== 城市数据 ====================
puts "正在初始化城市数据..."
City.destroy_all

# 中国主要城市数据（包含机场代码和主题标签）
cities_data = [
  # 直辖市
  { name: "北京", pinyin: "beijing", airport_code: "PEK", region: "北京", is_hot: true, themes: ["热门目的地", "亲子必去"] },
  { name: "上海", pinyin: "shanghai", airport_code: "SHA", region: "上海", is_hot: true, themes: ["热门目的地", "亲子必去"] },
  { name: "天津", pinyin: "tianjin", airport_code: "TSN", region: "天津", is_hot: false, themes: ["海边度假"] },
  { name: "重庆", pinyin: "chongqing", airport_code: "CKG", region: "重庆", is_hot: true, themes: ["热门目的地"] },
  
  # 广东省
  { name: "广州", pinyin: "guangzhou", airport_code: "CAN", region: "广东", is_hot: true, themes: ["热门目的地", "亲子必去"] },
  { name: "深圳", pinyin: "shenzhen", airport_code: "SZX", region: "广东", is_hot: true, themes: ["热门目的地", "海边度假"] },
  { name: "珠海", pinyin: "zhuhai", airport_code: "ZUH", region: "广东", is_hot: true, themes: ["海边度假", "亲子必去"] },
  { name: "汕头", pinyin: "shantou", airport_code: "SWA", region: "广东", is_hot: false, themes: ["海边度假"] },
  { name: "湛江", pinyin: "zhanjiang", airport_code: "ZHA", region: "广东", is_hot: false, themes: ["海边度假"] },
  
  # 浙江省
  { name: "杭州", pinyin: "hangzhou", airport_code: "HGH", region: "浙江", is_hot: true, themes: ["热门目的地", "亲子必去"] },
  { name: "宁波", pinyin: "ningbo", airport_code: "NGB", region: "浙江", is_hot: false, themes: ["海边度假"] },
  { name: "温州", pinyin: "wenzhou", airport_code: "WNZ", region: "浙江", is_hot: false, themes: [] },
  { name: "舟山", pinyin: "zhoushan", airport_code: "HSN", region: "浙江", is_hot: false, themes: ["海边度假"] },
  { name: "台州", pinyin: "taizhou", airport_code: "HYN", region: "浙江", is_hot: false, themes: ["海边度假"] },
  
  # 江苏省
  { name: "南京", pinyin: "nanjing", airport_code: "NKG", region: "江苏", is_hot: true, themes: ["热门目的地", "亲子必去"] },
  { name: "苏州", pinyin: "suzhou", airport_code: "SZV", region: "江苏", is_hot: false, themes: ["亲子必去"] },
  { name: "无锡", pinyin: "wuxi", airport_code: "WUX", region: "江苏", is_hot: false, themes: [] },
  { name: "连云港", pinyin: "lianyungang", airport_code: "LYG", region: "江苏", is_hot: false, themes: ["海边度假"] },
  { name: "南通", pinyin: "nantong", airport_code: "NTG", region: "江苏", is_hot: false, themes: ["海边度假"] },
  
  # 四川省
  { name: "成都", pinyin: "chengdu", airport_code: "CTU", region: "四川", is_hot: true, themes: ["热门目的地", "亲子必去"] },
  { name: "乐山", pinyin: "leshan", airport_code: "LMS", region: "四川", is_hot: false, themes: [] },
  { name: "九寨沟", pinyin: "jiuzhaigou", airport_code: "JZH", region: "四川", is_hot: false, themes: [] },
  
  # 陕西省
  { name: "西安", pinyin: "xian", airport_code: "XIY", region: "陕西", is_hot: true, themes: ["热门目的地", "亲子必去"] },
  { name: "延安", pinyin: "yanan", airport_code: "ENY", region: "陕西", is_hot: false, themes: [] },
  { name: "汉中", pinyin: "hanzhong", airport_code: "HZG", region: "陕西", is_hot: false, themes: [] },
  
  # 湖北省
  { name: "武汉", pinyin: "wuhan", airport_code: "WUH", region: "湖北", is_hot: true, themes: ["热门目的地"] },
  { name: "宜昌", pinyin: "yichang", airport_code: "YIH", region: "湖北", is_hot: false, themes: [] },
  { name: "襄阳", pinyin: "xiangyang", airport_code: "XFN", region: "湖北", is_hot: false, themes: [] },
  
  # 湖南省
  { name: "长沙", pinyin: "changsha", airport_code: "CSX", region: "湖南", is_hot: false, themes: [] },
  { name: "张家界", pinyin: "zhangjiajie", airport_code: "DYG", region: "湖南", is_hot: false, themes: [] },
  { name: "凤凰", pinyin: "fenghuang", airport_code: "TEN", region: "湖南", is_hot: false, themes: [] },
  
  # 福建省
  { name: "厦门", pinyin: "xiamen", airport_code: "XMN", region: "福建", is_hot: true, themes: ["热门目的地", "海边度假", "亲子必去"] },
  { name: "福州", pinyin: "fuzhou", airport_code: "FOC", region: "福建", is_hot: false, themes: ["海边度假"] },
  { name: "泉州", pinyin: "quanzhou", airport_code: "JJN", region: "福建", is_hot: false, themes: ["海边度假"] },
  { name: "平潭", pinyin: "pingtan", airport_code: "FOC", region: "福建", is_hot: false, themes: ["海边度假"] },
  
  # 海南省
  { name: "三亚", pinyin: "sanya", airport_code: "SYX", region: "海南", is_hot: true, themes: ["热门目的地", "海边度假", "亲子必去"] },
  { name: "海口", pinyin: "haikou", airport_code: "HAK", region: "海南", is_hot: false, themes: ["海边度假"] },
  { name: "万宁", pinyin: "wanning", airport_code: "SYX", region: "海南", is_hot: false, themes: ["海边度假"] },
  { name: "陵水", pinyin: "lingshui", airport_code: "SYX", region: "海南", is_hot: false, themes: ["海边度假"] },
  
  # 辽宁省
  { name: "沈阳", pinyin: "shenyang", airport_code: "SHE", region: "辽宁", is_hot: false, themes: [] },
  { name: "大连", pinyin: "dalian", airport_code: "DLC", region: "辽宁", is_hot: false, themes: ["海边度假"] },
  { name: "丹东", pinyin: "dandong", airport_code: "DDG", region: "辽宁", is_hot: false, themes: ["海边度假"] },
  
  # 黑龙江省
  { name: "哈尔滨", pinyin: "haerbin", airport_code: "HRB", region: "黑龙江", is_hot: true, themes: ["热门目的地"] },
  { name: "齐齐哈尔", pinyin: "qiqihaer", airport_code: "NDG", region: "黑龙江", is_hot: false, themes: [] },
  { name: "牡丹江", pinyin: "mudanjiang", airport_code: "MDG", region: "黑龙江", is_hot: false, themes: [] },
  
  # 吉林省
  { name: "长春", pinyin: "changchun", airport_code: "CGQ", region: "吉林", is_hot: false, themes: [] },
  { name: "吉林", pinyin: "jilin", airport_code: "JIL", region: "吉林", is_hot: false, themes: [] },
  { name: "延边", pinyin: "yanbian", airport_code: "YNJ", region: "吉林", is_hot: false, themes: [] },
  
  # 山东省
  { name: "青岛", pinyin: "qingdao", airport_code: "TAO", region: "山东", is_hot: false, themes: ["海边度假", "亲子必去"] },
  { name: "济南", pinyin: "jinan", airport_code: "TNA", region: "山东", is_hot: false, themes: [] },
  { name: "烟台", pinyin: "yantai", airport_code: "YNT", region: "山东", is_hot: false, themes: ["海边度假"] },
  { name: "威海", pinyin: "weihai", airport_code: "WEH", region: "山东", is_hot: false, themes: ["海边度假"] },
  { name: "日照", pinyin: "rizhao", airport_code: "RIZ", region: "山东", is_hot: false, themes: ["海边度假"] },
  
  # 云南省
  { name: "昆明", pinyin: "kunming", airport_code: "KMG", region: "云南", is_hot: false, themes: [] },
  { name: "丽江", pinyin: "lijiang", airport_code: "LJG", region: "云南", is_hot: false, themes: [] },
  { name: "大理", pinyin: "dali", airport_code: "DLU", region: "云南", is_hot: false, themes: [] },
  { name: "西双版纳", pinyin: "xishuangbanna", airport_code: "JHG", region: "云南", is_hot: false, themes: [] },
  { name: "香格里拉", pinyin: "xianggelila", airport_code: "DIG", region: "云南", is_hot: false, themes: [] },
  
  # 贵州省
  { name: "贵阳", pinyin: "guiyang", airport_code: "KWE", region: "贵州", is_hot: false, themes: [] },
  { name: "安顺", pinyin: "anshun", airport_code: "AVA", region: "贵州", is_hot: false, themes: [] },
  { name: "凯里", pinyin: "kaili", airport_code: "KWE", region: "贵州", is_hot: false, themes: [] },
  
  # 山西省
  { name: "太原", pinyin: "taiyuan", airport_code: "TYN", region: "山西", is_hot: false, themes: [] },
  { name: "大同", pinyin: "datong", airport_code: "DAT", region: "山西", is_hot: false, themes: [] },
  { name: "平遥", pinyin: "pingyao", airport_code: "TYN", region: "山西", is_hot: false, themes: [] },
  
  # 河北省
  { name: "石家庄", pinyin: "shijiazhuang", airport_code: "SJW", region: "河北", is_hot: false, themes: [] },
  { name: "秦皇岛", pinyin: "qinhuangdao", airport_code: "SHP", region: "河北", is_hot: false, themes: ["海边度假"] },
  { name: "承德", pinyin: "chengde", airport_code: "CDE", region: "河北", is_hot: false, themes: [] },
  
  # 河南省
  { name: "郑州", pinyin: "zhengzhou", airport_code: "CGO", region: "河南", is_hot: false, themes: [] },
  { name: "洛阳", pinyin: "luoyang", airport_code: "LYA", region: "河南", is_hot: false, themes: [] },
  { name: "开封", pinyin: "kaifeng", airport_code: "CGO", region: "河南", is_hot: false, themes: [] },
  
  # 安徽省
  { name: "合肥", pinyin: "hefei", airport_code: "HFE", region: "安徽", is_hot: false, themes: [] },
  { name: "黄山", pinyin: "huangshan", airport_code: "TXN", region: "安徽", is_hot: false, themes: [] },
  { name: "芜湖", pinyin: "wuhu", airport_code: "WHU", region: "安徽", is_hot: false, themes: [] },
  
  # 江西省
  { name: "南昌", pinyin: "nanchang", airport_code: "KHN", region: "江西", is_hot: false, themes: [] },
  { name: "景德镇", pinyin: "jingdezhen", airport_code: "JDZ", region: "江西", is_hot: false, themes: [] },
  { name: "九江", pinyin: "jiujiang", airport_code: "JIU", region: "江西", is_hot: false, themes: [] },
  
  # 广西省
  { name: "南宁", pinyin: "nanning", airport_code: "NNG", region: "广西", is_hot: false, themes: [] },
  { name: "桂林", pinyin: "guilin", airport_code: "KWL", region: "广西", is_hot: false, themes: [] },
  { name: "北海", pinyin: "beihai", airport_code: "BHY", region: "广西", is_hot: false, themes: ["海边度假"] },
  { name: "防城港", pinyin: "fangchenggang", airport_code: "BHY", region: "广西", is_hot: false, themes: ["海边度假"] },
  
  # 新疆自治区
  { name: "乌鲁木齐", pinyin: "wulumuqi", airport_code: "URC", region: "新疆", is_hot: false, themes: [] },
  { name: "喀什", pinyin: "kashi", airport_code: "KHG", region: "新疆", is_hot: false, themes: [] },
  { name: "伊犁", pinyin: "yili", airport_code: "YIN", region: "新疆", is_hot: false, themes: [] },
  
  # 西藏自治区
  { name: "拉萨", pinyin: "lasa", airport_code: "LXA", region: "西藏", is_hot: false, themes: [] },
  { name: "林芝", pinyin: "linzhi", airport_code: "LZY", region: "西藏", is_hot: false, themes: [] },
  { name: "日喀则", pinyin: "rikaze", airport_code: "RKZ", region: "西藏", is_hot: false, themes: [] },
  
  # 内蒙古自治区
  { name: "呼和浩特", pinyin: "huhehaote", airport_code: "HET", region: "内蒙古", is_hot: false, themes: [] },
  { name: "呼伦贝尔", pinyin: "hulunbeier", airport_code: "HLD", region: "内蒙古", is_hot: false, themes: [] },
  { name: "鄂尔多斯", pinyin: "eerduosi", airport_code: "DSN", region: "内蒙古", is_hot: false, themes: [] },
  
  # 宁夏自治区
  { name: "银川", pinyin: "yinchuan", airport_code: "INC", region: "宁夏", is_hot: false, themes: [] },
  { name: "中卫", pinyin: "zhongwei", airport_code: "ZHY", region: "宁夏", is_hot: false, themes: [] },
  { name: "固原", pinyin: "guyuan", airport_code: "GYU", region: "宁夏", is_hot: false, themes: [] },
  
  # 青海省
  { name: "西宁", pinyin: "xining", airport_code: "XNN", region: "青海", is_hot: false, themes: [] },
  { name: "格尔木", pinyin: "geermu", airport_code: "GOQ", region: "青海", is_hot: false, themes: [] },
  { name: "德令哈", pinyin: "delingha", airport_code: "HXD", region: "青海", is_hot: false, themes: [] },
  
  # 甘肃省
  { name: "兰州", pinyin: "lanzhou", airport_code: "LHW", region: "甘肃", is_hot: false, themes: [] },
  { name: "敦煌", pinyin: "dunhuang", airport_code: "DNH", region: "甘肃", is_hot: false, themes: [] },
  { name: "嘉峪关", pinyin: "jiayuguan", airport_code: "JGN", region: "甘肃", is_hot: false, themes: [] },
  
  # 特别行政区
  { name: "中国香港", pinyin: "xianggang", airport_code: "HKG", region: "香港", is_hot: true, themes: ["热门目的地", "亲子必去"] },
  { name: "中国澳门", pinyin: "aomen", airport_code: "MFM", region: "澳门", is_hot: true, themes: ["热门目的地"] },
  
  # 台湾省
  { name: "台北", pinyin: "taibei", airport_code: "TPE", region: "台湾", is_hot: false, themes: [] },
  { name: "高雄", pinyin: "gaoxiong", airport_code: "KHH", region: "台湾", is_hot: false, themes: [] },
  { name: "台中", pinyin: "taizhong", airport_code: "RMQ", region: "台湾", is_hot: false, themes: [] },
]

cities = cities_data.map do |data|
  City.create!(data)
end

puts "创建了 #{cities.count} 个城市"

# ==================== 旅游目的地数据 ====================
# 清理旧数据
puts "正在清理旧数据..."
TourProduct.destroy_all
Destination.destroy_all

puts "正在创建旅游目的地..."

# 创建热门目的地
destinations_data = [
  { name: "深圳", region: "广东", is_hot: true, description: "创新之都，现代化滨海城市" },
  { name: "北京", region: "北京", is_hot: true, description: "千年古都，文化名城" },
  { name: "上海", region: "上海", is_hot: true, description: "魔都，国际化大都市" },
  { name: "广州", region: "广东", is_hot: true, description: "千年商都，美食之城" },
  { name: "成都", region: "四川", is_hot: true, description: "天府之国,休闲之都" },
  { name: "杭州", region: "浙江", is_hot: true, description: "人间天堂，西湖美景" },
  { name: "西安", region: "陕西", is_hot: true, description: "十三朝古都，历史名城" },
  { name: "三亚", region: "海南", is_hot: true, description: "东方夏威夷，热带海滨" },
  { name: "珠海", region: "广东", is_hot: true, description: "浪漫之城，海滨花园" },
  { name: "中国香港", region: "香港", is_hot: true, description: "东方之珠，购物天堂" },
  { name: "中国澳门", region: "澳门", is_hot: true, description: "赌城，中西文化交汇" },
  { name: "哈尔滨", region: "黑龙江", is_hot: true, description: "冰城，冬季奇观" }
]

destinations = destinations_data.map do |data|
  Destination.create!(data)
end

puts "创建了 #{destinations.count} 个热门目的地"

# 为所有城市自动创建 Destination 记录（如果尚未存在）
puts "正在为所有城市创建 Destination 记录..."
created_count = 0
City.find_each do |city|
  # 使用 find_or_create_by 避免重复创建
  destination = Destination.find_or_create_by(name: city.name) do |dest|
    dest.region = city.region
    dest.is_hot = city.is_hot
    dest.description = "探索#{city.name}的美好"
    created_count += 1
  end
end
puts "为城市创建了 #{created_count} 个新的 Destination 记录"
puts "Destination 总数: #{Destination.count}"

# 为深圳创建详细的旅游产品
shenzhen = Destination.find_by(name: "深圳")

if shenzhen
  puts "正在为深圳创建旅游产品..."
  
  # 必去景点榜
  attractions = [
    {
      name: "深圳世界之窗",
      product_type: "attraction",
      category: "local",
      price: 180,
      original_price: 200,
      sales_count: 15000,
      rating: 4.5,
      tags: ["必去景点", "世界缩影景观"],
      description: "世界缩影景观，畅玩迪士尼",
      image_url: "https://images.unsplash.com/photo-1549813069-f95e44d7f498?w=800",
      rank: 1,
      is_featured: true
    },
    {
      name: "深圳野生动物园",
      product_type: "attraction",
      category: "local",
      price: 240,
      original_price: 260,
      sales_count: 12000,
      rating: 4.6,
      tags: ["必去景点", "看可爱国宝萌萌"],
      description: "看可爱国宝萌萌哒",
      image_url: "https://images.unsplash.com/photo-1564760055775-d63b17a55c44?w=800",
      rank: 2,
      is_featured: true
    },
    {
      name: "深圳欢乐谷",
      product_type: "attraction",
      category: "local",
      price: 230,
      original_price: 250,
      sales_count: 18000,
      rating: 4.7,
      tags: ["必去景点", "网红主题乐园"],
      description: "网红主题乐园，大型摩天轮刺激项目",
      image_url: "https://images.unsplash.com/photo-1594922009998-e5e0b9a9dbd6?w=800",
      rank: 3,
      is_featured: true
    }
  ]
  
  # 必住酒店榜
  hotels = [
    {
      name: "榆溪居·高空城景房",
      product_type: "hotel",
      category: "local",
      price: 457,
      original_price: 600,
      sales_count: 8000,
      rating: 4.8,
      tags: ["必住酒店", "多店通兑", "城市CBD"],
      description: "深圳酒店预订端吉康莱德文华东方四季丽思卡尔顿洲际希尔顿凯悦",
      image_url: "https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800",
      rank: 1,
      is_featured: true
    },
    {
      name: "卡罗酒店(深圳机场店)",
      product_type: "hotel",
      category: "local",
      price: 236,
      original_price: 300,
      sales_count: 6500,
      rating: 4.5,
      tags: ["必住酒店"],
      description: "近机场，交通便利",
      image_url: "https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=800",
      rank: 2,
      is_featured: true
    },
    {
      name: "维也纳酒店(深圳北站店)",
      product_type: "hotel",
      category: "local",
      price: 290,
      original_price: 350,
      sales_count: 7200,
      rating: 4.6,
      tags: ["必住酒店"],
      description: "近高铁站，便捷出行",
      image_url: "https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=800",
      rank: 3,
      is_featured: true
    }
  ]
  
  # 当地体验
  experiences = [
    {
      name: "深圳酒店预订瑞吉康莱德文华东方四季丽思卡尔顿洲际希尔顿凯悦",
      product_type: "hotel",
      category: "experience",
      price: 100,
      original_price: 150,
      sales_count: 8000,
      rating: 4.7,
      tags: ["多店通兑", "城市CBD"],
      description: "多店通兑，城市CBD",
      image_url: "https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800",
      rank: 1,
      is_featured: false
    },
    {
      name: "[光明农场大观园-大门票]光明农场大观园官方票",
      product_type: "attraction",
      category: "experience",
      price: 68,
      original_price: 80,
      sales_count: 3000,
      rating: 4.4,
      tags: ["16:50前可订今日票"],
      description: "生态农场体验，亲近自然",
      image_url: "https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=800",
      rank: 2,
      is_featured: false
    },
    {
      name: "深圳欢博索尼碗花园抗疲机场住宿新方式",
      product_type: "attraction",
      category: "experience",
      price: 300,
      original_price: 400,
      sales_count: 2500,
      rating: 4.3,
      tags: ["机场住宿"],
      description: "机场休息新体验",
      image_url: "https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=800",
      rank: 3,
      is_featured: false
    }
  ]
  
  # 当地跟团游
  local_tours = [
    {
      name: "【深圳-广州长隆野生动物世界-广州长隆欢乐世界双园1日游】",
      product_type: "tour",
      category: "local",
      price: 299,
      original_price: 350,
      sales_count: 5000,
      rating: 4.6,
      tags: ["双园通玩"],
      description: "长隆双园畅玩一日游",
      image_url: "https://images.unsplash.com/photo-1564760055775-d63b17a55c44?w=800",
      rank: 1,
      is_featured: false
    },
    {
      name: "深圳-香港海洋公园纯玩一日游",
      product_type: "tour",
      category: "local",
      price: 450,
      original_price: 550,
      sales_count: 4200,
      rating: 4.7,
      tags: ["含门票", "纯玩"],
      description: "香港海洋公园精华游",
      image_url: "https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=800",
      rank: 2,
      is_featured: false
    }
  ]
  
  # 周边跟团游
  nearby_tours = [
    {
      name: "【广州-珠海长隆海洋王国1日游】",
      product_type: "tour",
      category: "nearby",
      price: 320,
      original_price: 380,
      sales_count: 6000,
      rating: 4.7,
      tags: ["海洋王国", "亲子"],
      description: "珠海长隆海洋王国欢乐之旅",
      image_url: "https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=800",
      rank: 1,
      is_featured: false
    },
    {
      name: "【惠州-双月湾+巽寮湾2日游】",
      product_type: "tour",
      category: "nearby",
      price: 580,
      original_price: 680,
      sales_count: 3500,
      rating: 4.5,
      tags: ["海边度假", "两日游"],
      description: "惠州海滨风情两日游",
      image_url: "https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=800",
      rank: 2,
      is_featured: false
    }
  ]
  
  # 四季游
  seasonal_products = [
    {
      name: "深圳观澜山水田园温泉度假村门票",
      product_type: "attraction",
      category: "seasonal",
      price: 120,
      original_price: 168,
      sales_count: 2800,
      rating: 4.4,
      tags: ["温泉", "度假"],
      description: "温泉养生，田园风光",
      image_url: "https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=800",
      rank: 1,
      is_featured: false
    }
  ]
  
  # 创建所有产品
  all_products = attractions + hotels + experiences + local_tours + nearby_tours + seasonal_products
  
  all_products.each do |product_data|
    shenzhen.tour_products.create!(product_data)
  end
  
  puts "为深圳创建了 #{all_products.count} 个旅游产品"
end

puts "数据初始化完成！"

# ==================== 酒店数据 ====================
puts "正在创建酒店数据..."
Hotel.destroy_all

# 深圳酒店数据
shenzhen_hotels = [
  {
    name: "深圳南山大道希尔顿花园酒店",
    city: "深圳市",
    address: "南山区前海路",
    rating: 4.6,
    price: 701,
    original_price: 716,
    distance: "距您直线3千米",
    features: ["豪华", "高端", "商务"],
    star_level: 5,
    image_url: "https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80",
    is_featured: true,
    display_order: 1,
    hotel_type: 'hotel',
    is_domestic: true,
    region: '南山区'
  },
  {
    name: "深圳湾科技园丽雅尔酒店",
    city: "深圳市",
    address: "南山区科苑路",
    rating: 4.8,
    price: 542,
    original_price: 658,
    distance: "距您直线269米",
    features: ["豪华", "交通特别方便"],
    star_level: 4,
    image_url: "https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=800&q=80",
    is_featured: true,
    display_order: 2,
    hotel_type: 'hotel',
    is_domestic: true,
    region: '南山区'
  },
  {
    name: "深圳福田区威斯汀酒店",
    city: "深圳市",
    address: "福田区福华路",
    rating: 4.5,
    price: 386,
    original_price: 480,
    distance: "距福田高铁站1.5千米",
    features: ["精选", "干净卫生"],
    star_level: 4,
    image_url: "https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=800&q=80",
    is_featured: false,
    display_order: 3,
    hotel_type: 'hotel',
    is_domestic: true,
    region: '福田区'
  },
  {
    name: "深圳罗湖区维也纳国际酒店",
    city: "深圳市",
    address: "罗湖区人民南路",
    rating: 4.4,
    price: 298,
    original_price: 350,
    distance: "距罗湖口岸1千米",
    features: ["经济型", "交通便利"],
    star_level: 3,
    image_url: "https://images.unsplash.com/photo-1618773928121-c32242e63f39?w=800&q=80",
    is_featured: false,
    display_order: 4,
    hotel_type: 'hotel',
    is_domestic: true,
    region: '罗湖区'
  },
  {
    name: "深圳宝安机场凯悦酒店",
    city: "深圳市",
    address: "宝安区机场路",
    rating: 4.7,
    price: 458,
    original_price: 580,
    distance: "距宝安机场500米",
    features: ["机场附近", "接送机服务"],
    star_level: 4,
    image_url: "https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=800&q=80",
    is_featured: false,
    display_order: 5,
    hotel_type: 'hotel',
    is_domestic: true,
    region: '宝安区'
  },
  {
    name: "深圳欢乐港湾度假酒店",
    city: "深圳市",
    address: "宝安区海滨路",
    rating: 4.6,
    price: 520,
    original_price: 650,
    distance: "距欢乐港湾200米",
    features: ["海景房", "度假休闲"],
    star_level: 4,
    image_url: "https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=800&q=80",
    is_featured: false,
    display_order: 6,
    hotel_type: 'hotel',
    is_domestic: true,
    region: '宝安区'
  },
  {
    name: "深圳东门商务酒店",
    city: "深圳市",
    address: "罗湖区东门老街",
    rating: 4.3,
    price: 256,
    original_price: 320,
    distance: "距东门老街100米",
    features: ["经济型", "老街附近"],
    star_level: 3,
    image_url: "https://images.unsplash.com/photo-1590490360182-c33d57733427?w=800&q=80",
    is_featured: false,
    display_order: 7,
    hotel_type: 'hotel',
    is_domestic: true,
    region: '罗湖区'
  },
  {
    name: "深圳北站希尔顿酒店",
    city: "深圳市",
    address: "龙华区民治街道",
    rating: 4.7,
    price: 680,
    original_price: 800,
    distance: "距深圳北站300米",
    features: ["高铁站附近", "国际品牌"],
    star_level: 5,
    image_url: "https://images.unsplash.com/photo-1564501049412-61c2a3083791?w=800&q=80",
    is_featured: false,
    display_order: 8,
    hotel_type: 'hotel',
    is_domestic: true,
    region: '龙华区'
  },
  {
    name: "深圳西乡塑望酽酒店",
    city: "深圳市",
    address: "南山区深南大道",
    rating: 4.5,
    price: 428,
    original_price: 520,
    distance: "距西乡塔千米",
    features: ["商务酒店", "景观房"],
    star_level: 4,
    image_url: "https://images.unsplash.com/photo-1596436889106-be35e843f974?w=800&q=80",
    is_featured: false,
    display_order: 9,
    hotel_type: 'hotel',
    is_domestic: true,
    region: '南山区'
  },
  {
    name: "深圳大棅湾海滨度假村",
    city: "深圳市",
    address: "龙岗区大棅湾",
    rating: 4.8,
    price: 880,
    original_price: 1200,
    distance: "距深圳市中心30千米",
    features: ["海边度假", "别墅酒店"],
    star_level: 5,
    image_url: "https://images.unsplash.com/photo-1584132967334-10e028bd69f7?w=800&q=80",
    is_featured: true,
    display_order: 10,
    hotel_type: 'hotel',
    is_domestic: true,
    region: '龙岗区'
  },
  # 民宿
  {
    name: "深圳南山区海景民宿",
    city: "深圳市",
    address: "南山区蛇口海上世界",
    rating: 4.9,
    price: 380,
    original_price: 450,
    distance: "距海上世界300米",
    features: ["民宿", "海景", "温馨"],
    star_level: nil,
    image_url: "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800&q=80",
    is_featured: true,
    display_order: 11,
    hotel_type: 'homestay',
    is_domestic: true,
    region: '南山区'
  },
  {
    name: "深圳大梅沙海边民宿",
    city: "深圳市",
    address: "盐田区大梅沙",
    rating: 4.7,
    price: 280,
    original_price: 350,
    distance: "距大梅沙海滨100米",
    features: ["民宿", "海边", "亲子"],
    star_level: nil,
    image_url: "https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800&q=80",
    is_featured: false,
    display_order: 12,
    hotel_type: 'homestay',
    is_domestic: true,
    region: '盐田区'
  },
  {
    name: "深圳华侨城艺术民宿",
    city: "深圳市",
    address: "南山区华侨城",
    rating: 4.8,
    price: 420,
    original_price: 500,
    distance: "距欢乐谷500米",
    features: ["民宿", "艺术", "设计感"],
    star_level: nil,
    image_url: "https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=800&q=80",
    is_featured: false,
    display_order: 13,
    hotel_type: 'homestay',
    is_domestic: true,
    region: '南山区'
  }
]

shenzhen_hotels.each do |hotel_data|
  hotel = Hotel.create!(hotel_data)
  
  # 为每个酒店和民宿创建过夜房型
  overnight_rooms = [
    { room_type: "豪华大床房", bed_type: "大床", price: hotel.price, original_price: hotel.original_price, area: "35㎡", max_guests: 2, has_window: true, available_rooms: 5, room_category: 'overnight' },
    { room_type: "高级双人房", bed_type: "双床", price: hotel.price + 50, original_price: hotel.original_price + 80, area: "38㎡", max_guests: 2, has_window: true, available_rooms: 8, room_category: 'overnight' }
  ]
  
  overnight_rooms.each do |room_data|
    hotel.hotel_rooms.create!(room_data)
  end
  
  # 部分酒店和民宿提供钟点房（60%概率）
  if rand < 0.6
    hourly_rooms = [
      { room_type: "2小时房", bed_type: "大床", price: (hotel.price * 0.3).round(0), original_price: (hotel.price * 0.35).round(0), area: "25㎡", max_guests: 2, has_window: true, available_rooms: 3, room_category: 'hourly' },
      { room_type: "3小时房", bed_type: "大床", price: (hotel.price * 0.4).round(0), original_price: (hotel.price * 0.45).round(0), area: "28㎡", max_guests: 2, has_window: true, available_rooms: 2, room_category: 'hourly' }
    ]
    
    hourly_rooms.each do |room_data|
      hotel.hotel_rooms.create!(room_data)
    end
  end
end

puts "创建了 #{Hotel.count} 个酒店和 #{HotelRoom.count} 个房型"

puts "
\n✅ 所有数据初始化完成！"
puts "🏛  城市: #{City.count} 个"
puts "🌍 目的地: #{Destination.count} 个"
puts "🏞  旅游产品: #{TourProduct.count} 个"
puts "🏨 酒店: #{Hotel.count} 个"
puts "🚪 房型: #{HotelRoom.count} 个"
# ==================== 火车票数据 ====================
puts "正在初始化火车票数据..."
Train.destroy_all

# 使用自动生成功能为热门线路预生成今天和明天的数据
# 其他日期和路线将在搜索时自动生成
popular_routes = [
  ['北京', '杭州'],
  ['杭州', '北京'],
  ['北京', '上海'],
  ['上海', '北京'],
  ['深圳', '广州'],
  ['广州', '深圳']
]

trains_created = 0
(0..1).each do |day_offset|
  target_date = Date.today + day_offset.days
  popular_routes.each do |departure, arrival|
    generated = Train.generate_for_route(departure, arrival, target_date)
    trains_created += generated.count
  end
end

puts "预生成了 #{trains_created} 条火车票记录 (热门线路今明两天)"
puts "其他线路和日期将在搜索时自动生成"
puts "火车票数据初始化完成！"

# ==================== 会员权益数据 ====================
puts "正在初始化会员权益数据..."
MembershipBenefit.destroy_all

benefits_data = [
  { name: "专属折扣", level_required: "F1", icon: "💰", description: "享受会员专属优惠价格" },
  { name: "优先客服", level_required: "F1", icon: "🎧", description: "专属客服优先响应" },
  { name: "积分翻倍", level_required: "F2", icon: "🎁", description: "订单积分双倍返还" },
  { name: "免费升舱", level_required: "F3", icon: "✈️", description: "机票自动升舱机会" },
  { name: "贵宾休息室", level_required: "F4", icon: "☕", description: "机场贵宾室免费使用" },
  { name: "专属管家", level_required: "F5", icon: "👔", description: "7x24小时专属管家服务" }
]

benefits_data.each do |data|
  MembershipBenefit.create!(data)
end

puts "创建了 #{MembershipBenefit.count} 个会员权益"
puts "会员权益数据初始化完成！"

# ==================== 示例用户和行程数据 ====================
# 注：仅用于开发测试,生产环境请删除
if Rails.env.development?
  puts "正在创建示例用户和行程数据..."
  
  # 创建测试用户（如果不存在）
  demo_user = User.find_or_create_by!(email: 'demo@example.com') do |u|
    u.password = 'password123'
    u.password_confirmation = 'password123'
    u.verified = true
  end
  
  # 确保用户有会员资格
  unless demo_user.membership
    demo_user.create_membership!(level: 'F2', points: 150, experience: 80)
  end
  
  # 清理旧行程
  demo_user.itineraries.destroy_all
  
  # 创建即将到来的行程
  itinerary = demo_user.itineraries.create!(
    title: '武汉之行',
    start_date: Date.today + 10.days,
    end_date: Date.today + 13.days,
    destination: '武汉',
    status: 'upcoming'
  )
  
  # 创建航班项目
  flight = itinerary.itinerary_items.create!(
    item_type: 'flight',
    item_date: Date.today + 10.days,
    sequence: 1
  )
  
  puts "创建了示例用户 (#{demo_user.email}) 和 1 条行程"
  puts "示例数据初始化完成！"
end

puts "🚄 火车票: #{Train.count} 条"
puts "💎 会员权益: #{MembershipBenefit.count} 个"

# ==================== 深度旅游讲解员数据 ====================
puts "正在初始化深度旅游讲解员数据..."

video_path = Rails.root.join('app', 'assets', 'videos', '深度旅游-讲师-叶强.mov')

# 清理旧数据
DeepTravelProduct.destroy_all
DeepTravelGuide.destroy_all

# 创建讲解员数据
guides_data = [
  {
    name: "叶强",
    title: "北京导游协会金牌导游 故宫认证讲解员 北京卫视《紫禁城》嘉宾",
    description: "北京导游协会金牌导游，故宫认证讲解员，北京卫视《紫禁城》栏目特邀嘉宾。从事导游行业12年，专注故宫、颐和园、长城等北京经典景点深度讲解，对北京历史文化有独到见解。",
    follower_count: 100,
    experience_years: 10,
    specialties: "故宫深度讲解、明清历史、皇家园林、北京文化",
    price: 192.06,
    served_count: 10000,
    rank: 1,
    rating: 4.9,
    featured: true
  },
  {
    name: "惟真",
    title: "西安市金牌导游&高级导游",
    description: "西安市金牌导游，高级导游员。从事导游行业10年+，专注陕西历史文化景点讲解，对秦始皇兵马俑、华清池、西安城墙等景点有深入研究。",
    follower_count: 10,
    experience_years: 10,
    specialties: "兵马俑讲解、唐代历史、陕西文化、古代文明",
    price: 183.00,
    served_count: 6000,
    rank: 2,
    rating: 4.8,
    featured: true
  },
  {
    name: "贾建宇",
    title: "中国国家博物馆资深讲解员 历史考古学硕士",
    description: "中国国家博物馆资深讲解员，历史考古学硕士。专注于中国古代历史、考古文物的深度讲解。",
    follower_count: 10,
    experience_years: 8,
    specialties: "国家博物馆讲解、考古文物、中国历史、文物鉴赏",
    price: 156.88,
    served_count: 600,
    rank: 3,
    rating: 4.7,
    featured: true
  },
  {
    name: "蒋宏波",
    title: "北京文旅局重点团队领军人",
    description: "北京人，北京文旅局重点团队领军人物，毕业于北京旅游学院。对北京的历史文化有着深厚的理解和热爱。",
    follower_count: 1,
    experience_years: 10,
    specialties: "恭王府讲解、清代历史、北京文化、古建筑",
    price: 138.00,
    served_count: 300,
    rank: 4,
    rating: 4.6,
    featured: true
  },
  {
    name: "李文超",
    title: "上海资深导游 东方明珠讲解员",
    description: "上海资深导游，东方明珠特约讲解员。专注上海近现代史、外滩建筑、上海文化讲解，让游客深度了解上海的历史变迁。",
    follower_count: 8,
    experience_years: 8,
    specialties: "上海历史、外滩建筑、近代史、海派文化",
    price: 168.00,
    served_count: 5000,
    rank: 5,
    rating: 4.7,
    featured: true
  }
]

puts "正在创建讲解员..."
guides = guides_data.map do |data|
  guide = DeepTravelGuide.create!(data)
  
  # 为第一个讲解员附加视频
  if guide.name == "叶强" && File.exist?(video_path)
    guide.video.attach(
      io: File.open(video_path),
      filename: '深度旅游-讲师-叶强.mov',
      content_type: 'video/quicktime'
    )
    puts "  - 已为 #{guide.name} 附加视频"
  end
  
  guide
end

puts "创建了 #{guides.count} 个讲解员"

# ==================== 深度旅游产品数据 ====================
puts "正在创建深度旅游产品..."

ye_qiang = guides.find { |g| g.name == "叶强" }
wei_zhen = guides.find { |g| g.name == "惟真" }
jia_jianyu = guides.find { |g| g.name == "贾建宇" }
jiang_hongbo = guides.find { |g| g.name == "蒋宏波" }
li_wenchao = guides.find { |g| g.name == "李文超" }

products_data = [
  # 叶强 - 北京故宫相关产品
  {
    title: "北京故宫博物院讲解半日游【金牌资深讲师】",
    subtitle: "明清皇宫禁紫城",
    location: "北京",
    guide: ye_qiang,
    price: 28.00,
    sales_count: 200,
    description: "跟随金牌讲解员叶强，深度游览故宫博物院。了解明清两代皇家历史，探索紫禁城的建筑艺术与文化内涵。",
    itinerary: "午门集合 → 太和殿 → 中和殿 → 保和殿 → 乾清宫 → 坤宁宫 → 御花园",
    featured: true
  },
  {
    title: "北京故宫导游讲解私家团深度精讲私家团北京旅游私人定制",
    subtitle: "私家团 深度讲解",
    location: "北京",
    guide: ye_qiang,
    price: 80.00,
    sales_count: 44,
    description: "私家定制团，深度讲解故宫历史文化，专属导游服务，灵活安排行程。",
    itinerary: "根据客户需求定制行程",
    featured: false
  },
  {
    title: "北京颐和园深度讲解半日游",
    subtitle: "皇家园林 世界文化遗产",
    location: "北京",
    guide: ye_qiang,
    price: 158.00,
    sales_count: 120,
    description: "游览中国现存规模最大、保存最完整的皇家园林，了解清代皇家园林文化。",
    itinerary: "东宫门 → 仁寿殿 → 德和园 → 文昌院 → 玉澜堂 → 乐寿堂 → 长廊 → 排云殿 → 佛香阁 → 石舫 → 苏州街",
    featured: true
  },
  
  # 惟真 - 西安兵马俑相关产品
  {
    title: "盛迹说 西安秦始皇陵兵马俑金牌导游深度讲解",
    subtitle: "世界第八大奇迹",
    location: "陕西",
    guide: wei_zhen,
    price: 138.00,
    sales_count: 8,
    description: "金牌导游惟真带您深度探索秦始皇陵兵马俑，了解秦代历史文化，探寻两千年前的帝国辉煌。",
    itinerary: "秦始皇帝陵博物院 → 一号坑 → 二号坑 → 三号坑 → 铜车马展厅",
    featured: true
  },
  {
    title: "西安兵马俑+丽山园一日游含门票5H深度讲解",
    subtitle: "一日游 含门票 专车接送",
    location: "陕西",
    guide: wei_zhen,
    price: 118.00,
    sales_count: 300,
    description: "含门票、专车接送、5小时深度讲解，纯玩无购物，全方位了解秦始皇陵和兵马俑的历史文化。",
    itinerary: "酒店接 → 秦始皇陵 → 兵马俑博物馆 → 丽山园 → 返回酒店",
    featured: true
  },
  
  # 贾建宇 - 中国国家博物馆相关产品
  {
    title: "中国国家博物馆古代中国人工讲解含门票耳麦深度游",
    subtitle: "探索中华五千年文明",
    location: "北京",
    guide: jia_jianyu,
    price: 156.88,
    sales_count: 200,
    description: "资深讲解员贾建宇带您深度游览国家博物馆，从远古到明清，全面了解中国五千年文明史。",
    itinerary: "远古中国 → 夏商西周 → 春秋战国 → 秦汉 → 魏晋南北朝 → 隋唐 → 宋元明清",
    featured: true
  },
  
  # 蒋宏波 - 北京国博相关产品
  {
    title: "北京国博讲解【10人小团 含入馆】一日游国博深度讲解北京旅游",
    subtitle: "小团深度游 含门票",
    location: "北京",
    guide: jiang_hongbo,
    price: 118.00,
    sales_count: 200,
    description: "10人小团，深度讲解国家博物馆精华展品，含入馆服务，专业讲解员带您了解中国历史文化。",
    itinerary: "国家博物馆精华展品讲解",
    featured: false
  },
  {
    title: "恭王府深度讲解一日游",
    subtitle: "清代王府 和珅府邸",
    location: "北京",
    guide: jiang_hongbo,
    price: 98.00,
    sales_count: 150,
    description: "游览清代规模最大的王府，了解和珅的传奇故事，欣赏精美的王府建筑和园林。",
    itinerary: "府邸建筑 → 花园景观 → 和珅传奇故事",
    featured: false
  },
  
  # 李文超 - 上海相关产品
  {
    title: "上海外滩+东方明珠深度讲解半日游",
    subtitle: "魔都地标 近代史探索",
    location: "华东",
    guide: li_wenchao,
    price: 168.00,
    sales_count: 180,
    description: "资深导游李文超带您游览外滩万国建筑群，登顶东方明珠，了解上海近现代发展史。",
    itinerary: "外滩 → 南京路 → 东方明珠 → 浦东新区",
    featured: true
  },
  {
    title: "上海博物馆深度讲解游",
    subtitle: "中国古代艺术宝库",
    location: "华东",
    guide: li_wenchao,
    price: 128.00,
    sales_count: 90,
    description: "深度游览上海博物馆，欣赏青铜器、陶瓷、书画等珍贵文物，了解中国古代艺术。",
    itinerary: "青铜馆 → 陶瓷馆 → 书画馆 → 玉器馆",
    featured: false
  },
  
  # 添加华中地区产品
  {
    title: "武汉黄鹤楼+东湖深度讲解一日游",
    subtitle: "江南三大名楼之一",
    location: "华中",
    guide: ye_qiang,
    price: 188.00,
    sales_count: 65,
    description: "游览江南三大名楼之一的黄鹤楼，欣赏东湖美景，了解武汉的历史文化。",
    itinerary: "黄鹤楼 → 长江大桥 → 东湖风景区",
    featured: false
  }
]

products = products_data.map do |data|
  guide = data.delete(:guide)
  DeepTravelProduct.create!(data.merge(deep_travel_guide: guide))
end

puts "创建了 #{products.count} 个深度旅游产品"

puts "✅ 深度旅游数据加载完成！"
