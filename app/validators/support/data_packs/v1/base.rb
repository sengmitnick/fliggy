# frozen_string_literal: true

# 加载 activerecord-import gem（如果还没加载）
begin
  require 'activerecord-import' unless defined?(ActiveRecord::Import)
rescue LoadError
  # gem 可能还没加载，在 Rails 启动过程中稍后会自动加载
end

# base_v1 数据包
# 基础数据：City + Destination
# 
# 用途：
# - 所有验证器的依赖数据
# - Flight/Hotel 等业务数据需要引用 City
# - 用户界面需要展示城市列表和目的地
# 
# 加载时机：
# - BaseValidator#ensure_checkpoint 自动检查并加载
# - 或手动运行: rails runner "load Rails.root.join('app/validators/support/data_packs/v1/base.rb')"

puts "正在加载 base_v1 数据包..."

# ==================== 城市数据 ====================
puts "  → 正在加载城市数据..."

cities_data = [
  # 直辖市
  { name: "北京市", pinyin: "beijing", airport_code: "PEK", region: "北京", is_hot: true, themes: ["热门目的地", "亲子必去"] },
  { name: "上海市", pinyin: "shanghai", airport_code: "SHA", region: "上海", is_hot: true, themes: ["热门目的地", "亲子必去"] },
  { name: "天津市", pinyin: "tianjin", airport_code: "TSN", region: "天津", is_hot: false, themes: ["海边度假"] },
  { name: "重庆市", pinyin: "chongqing", airport_code: "CKG", region: "重庆", is_hot: true, themes: ["热门目的地"] },
  
  # 广东省
  { name: "广州市", pinyin: "guangzhou", airport_code: "CAN", region: "广东", is_hot: true, themes: ["热门目的地", "亲子必去"] },
  { name: "深圳市", pinyin: "shenzhen", airport_code: "SZX", region: "广东", is_hot: true, themes: ["热门目的地", "海边度假"] },
  { name: "珠海市", pinyin: "zhuhai", airport_code: "ZUH", region: "广东", is_hot: true, themes: ["海边度假", "亲子必去"] },
  { name: "汕头市", pinyin: "shantou", airport_code: "SWA", region: "广东", is_hot: false, themes: ["海边度假"] },
  { name: "湛江市", pinyin: "zhanjiang", airport_code: "ZHA", region: "广东", is_hot: false, themes: ["海边度假"] },
  
  # 浙江省
  { name: "杭州市", pinyin: "hangzhou", airport_code: "HGH", region: "浙江", is_hot: true, themes: ["热门目的地", "亲子必去"] },
  { name: "宁波市", pinyin: "ningbo", airport_code: "NGB", region: "浙江", is_hot: false, themes: ["海边度假"] },
  { name: "温州市", pinyin: "wenzhou", airport_code: "WNZ", region: "浙江", is_hot: false, themes: [] },
  { name: "舟山市", pinyin: "zhoushan", airport_code: "HSN", region: "浙江", is_hot: false, themes: ["海边度假"] },
  { name: "台州市", pinyin: "taizhou", airport_code: "HYN", region: "浙江", is_hot: false, themes: ["海边度假"] },
  
  # 江苏省
  { name: "南京市", pinyin: "nanjing", airport_code: "NKG", region: "江苏", is_hot: true, themes: ["热门目的地", "亲子必去"] },
  { name: "苏州市", pinyin: "suzhou", airport_code: "SZV", region: "江苏", is_hot: false, themes: ["亲子必去"] },
  { name: "无锡市", pinyin: "wuxi", airport_code: "WUX", region: "江苏", is_hot: false, themes: [] },
  { name: "连云港市", pinyin: "lianyungang", airport_code: "LYG", region: "江苏", is_hot: false, themes: ["海边度假"] },
  { name: "南通市", pinyin: "nantong", airport_code: "NTG", region: "江苏", is_hot: false, themes: ["海边度假"] },
  
  # 四川省
  { name: "成都市", pinyin: "chengdu", airport_code: "CTU", region: "四川", is_hot: true, themes: ["热门目的地", "亲子必去"] },
  { name: "乐山市", pinyin: "leshan", airport_code: "LMS", region: "四川", is_hot: false, themes: [] },
  { name: "九寨沟", pinyin: "jiuzhaigou", airport_code: "JZH", region: "四川", is_hot: false, themes: [] },
  
  # 陕西省
  { name: "西安市", pinyin: "xian", airport_code: "XIY", region: "陕西", is_hot: true, themes: ["热门目的地", "亲子必去"] },
  { name: "延安市", pinyin: "yanan", airport_code: "ENY", region: "陕西", is_hot: false, themes: [] },
  { name: "汉中市", pinyin: "hanzhong", airport_code: "HZG", region: "陕西", is_hot: false, themes: [] },
  
  # 湖北省
  { name: "武汉市", pinyin: "wuhan", airport_code: "WUH", region: "湖北", is_hot: true, themes: ["热门目的地"] },
  { name: "宜昌市", pinyin: "yichang", airport_code: "YIH", region: "湖北", is_hot: false, themes: [] },
  { name: "襄阳市", pinyin: "xiangyang", airport_code: "XFN", region: "湖北", is_hot: false, themes: [] },
  
  # 湖南省
  { name: "长沙市", pinyin: "changsha", airport_code: "CSX", region: "湖南", is_hot: false, themes: [] },
  { name: "张家界市", pinyin: "zhangjiajie", airport_code: "DYG", region: "湖南", is_hot: false, themes: [] },
  { name: "凤凰", pinyin: "fenghuang", airport_code: "TEN", region: "湖南", is_hot: false, themes: [] },
  
  # 福建省
  { name: "厦门市", pinyin: "xiamen", airport_code: "XMN", region: "福建", is_hot: true, themes: ["热门目的地", "海边度假", "亲子必去"] },
  { name: "福州市", pinyin: "fuzhou", airport_code: "FOC", region: "福建", is_hot: false, themes: ["海边度假"] },
  { name: "泉州市", pinyin: "quanzhou", airport_code: "JJN", region: "福建", is_hot: false, themes: ["海边度假"] },
  { name: "平潭", pinyin: "pingtan", airport_code: "FOC", region: "福建", is_hot: false, themes: ["海边度假"] },
  
  # 海南省
  { name: "三亚市", pinyin: "sanya", airport_code: "SYX", region: "海南", is_hot: true, themes: ["热门目的地", "海边度假", "亲子必去"] },
  { name: "海口市", pinyin: "haikou", airport_code: "HAK", region: "海南", is_hot: false, themes: ["海边度假"] },
  { name: "万宁市", pinyin: "wanning", airport_code: "SYX", region: "海南", is_hot: false, themes: ["海边度假"] },
  { name: "陵水", pinyin: "lingshui", airport_code: "SYX", region: "海南", is_hot: false, themes: ["海边度假"] },
  
  # 辽宁省
  { name: "沈阳市", pinyin: "shenyang", airport_code: "SHE", region: "辽宁", is_hot: false, themes: [] },
  { name: "大连市", pinyin: "dalian", airport_code: "DLC", region: "辽宁", is_hot: false, themes: ["海边度假"] },
  { name: "丹东市", pinyin: "dandong", airport_code: "DDG", region: "辽宁", is_hot: false, themes: ["海边度假"] },
  
  # 黑龙江省
  { name: "哈尔滨市", pinyin: "haerbin", airport_code: "HRB", region: "黑龙江", is_hot: true, themes: ["热门目的地"] },
  { name: "齐齐哈尔市", pinyin: "qiqihaer", airport_code: "NDG", region: "黑龙江", is_hot: false, themes: [] },
  { name: "牡丹江市", pinyin: "mudanjiang", airport_code: "MDG", region: "黑龙江", is_hot: false, themes: [] },
  
  # 吉林省
  { name: "长春市", pinyin: "changchun", airport_code: "CGQ", region: "吉林", is_hot: false, themes: [] },
  { name: "吉林市", pinyin: "jilin", airport_code: "JIL", region: "吉林", is_hot: false, themes: [] },
  { name: "延边", pinyin: "yanbian", airport_code: "YNJ", region: "吉林", is_hot: false, themes: [] },
  
  # 山东省
  { name: "青岛市", pinyin: "qingdao", airport_code: "TAO", region: "山东", is_hot: false, themes: ["海边度假", "亲子必去"] },
  { name: "济南市", pinyin: "jinan", airport_code: "TNA", region: "山东", is_hot: false, themes: [] },
  { name: "烟台市", pinyin: "yantai", airport_code: "YNT", region: "山东", is_hot: false, themes: ["海边度假"] },
  { name: "威海市", pinyin: "weihai", airport_code: "WEH", region: "山东", is_hot: false, themes: ["海边度假"] },
  { name: "日照市", pinyin: "rizhao", airport_code: "RIZ", region: "山东", is_hot: false, themes: ["海边度假"] },
  
  # 云南省
  { name: "昆明市", pinyin: "kunming", airport_code: "KMG", region: "云南", is_hot: false, themes: [] },
  { name: "丽江市", pinyin: "lijiang", airport_code: "LJG", region: "云南", is_hot: false, themes: [] },
  { name: "大理", pinyin: "dali", airport_code: "DLU", region: "云南", is_hot: false, themes: [] },
  { name: "西双版纳", pinyin: "xishuangbanna", airport_code: "JHG", region: "云南", is_hot: false, themes: [] },
  { name: "香格里拉", pinyin: "xianggelila", airport_code: "DIG", region: "云南", is_hot: false, themes: [] },
  
  # 贵州省
  { name: "贵阳市", pinyin: "guiyang", airport_code: "KWE", region: "贵州", is_hot: false, themes: [] },
  { name: "安顺市", pinyin: "anshun", airport_code: "AVA", region: "贵州", is_hot: false, themes: [] },
  { name: "凯里市", pinyin: "kaili", airport_code: "KWE", region: "贵州", is_hot: false, themes: [] },
  
  # 山西省
  { name: "太原市", pinyin: "taiyuan", airport_code: "TYN", region: "山西", is_hot: false, themes: [] },
  { name: "大同市", pinyin: "datong", airport_code: "DAT", region: "山西", is_hot: false, themes: [] },
  { name: "平遥", pinyin: "pingyao", airport_code: "TYN", region: "山西", is_hot: false, themes: [] },
  
  # 河北省
  { name: "石家庄市", pinyin: "shijiazhuang", airport_code: "SJW", region: "河北", is_hot: false, themes: [] },
  { name: "秦皇岛市", pinyin: "qinhuangdao", airport_code: "SHP", region: "河北", is_hot: false, themes: ["海边度假"] },
  { name: "承德市", pinyin: "chengde", airport_code: "CDE", region: "河北", is_hot: false, themes: [] },
  
  # 河南省
  { name: "郑州市", pinyin: "zhengzhou", airport_code: "CGO", region: "河南", is_hot: false, themes: [] },
  { name: "洛阳市", pinyin: "luoyang", airport_code: "LYA", region: "河南", is_hot: false, themes: [] },
  { name: "开封市", pinyin: "kaifeng", airport_code: "CGO", region: "河南", is_hot: false, themes: [] },
  
  # 安徽省
  { name: "合肥市", pinyin: "hefei", airport_code: "HFE", region: "安徽", is_hot: false, themes: [] },
  { name: "黄山市", pinyin: "huangshan", airport_code: "TXN", region: "安徽", is_hot: false, themes: [] },
  { name: "芜湖市", pinyin: "wuhu", airport_code: "WHU", region: "安徽", is_hot: false, themes: [] },
  
  # 江西省
  { name: "南昌市", pinyin: "nanchang", airport_code: "KHN", region: "江西", is_hot: false, themes: [] },
  { name: "景德镇市", pinyin: "jingdezhen", airport_code: "JDZ", region: "江西", is_hot: false, themes: [] },
  { name: "九江市", pinyin: "jiujiang", airport_code: "JIU", region: "江西", is_hot: false, themes: [] },
  
  # 广西省
  { name: "南宁市", pinyin: "nanning", airport_code: "NNG", region: "广西", is_hot: false, themes: [] },
  { name: "桂林市", pinyin: "guilin", airport_code: "KWL", region: "广西", is_hot: false, themes: [] },
  { name: "北海市", pinyin: "beihai", airport_code: "BHY", region: "广西", is_hot: false, themes: ["海边度假"] },
  { name: "防城港市", pinyin: "fangchenggang", airport_code: "BHY", region: "广西", is_hot: false, themes: ["海边度假"] },
  
  # 新疆自治区
  { name: "乌鲁木齐市", pinyin: "wulumuqi", airport_code: "URC", region: "新疆", is_hot: false, themes: [] },
  { name: "喀什市", pinyin: "kashi", airport_code: "KHG", region: "新疆", is_hot: false, themes: [] },
  { name: "伊犁", pinyin: "yili", airport_code: "YIN", region: "新疆", is_hot: false, themes: [] },
  
  # 西藏自治区
  { name: "拉萨市", pinyin: "lasa", airport_code: "LXA", region: "西藏", is_hot: false, themes: [] },
  { name: "林芝市", pinyin: "linzhi", airport_code: "LZY", region: "西藏", is_hot: false, themes: [] },
  { name: "日喀则市", pinyin: "rikaze", airport_code: "RKZ", region: "西藏", is_hot: false, themes: [] },
  
  # 内蒙古自治区
  { name: "呼和浩特市", pinyin: "huhehaote", airport_code: "HET", region: "内蒙古", is_hot: false, themes: [] },
  { name: "呼伦贝尔市", pinyin: "hulunbeier", airport_code: "HLD", region: "内蒙古", is_hot: false, themes: [] },
  { name: "鄂尔多斯市", pinyin: "eerduosi", airport_code: "DSN", region: "内蒙古", is_hot: false, themes: [] },
  
  # 宁夏自治区
  { name: "银川市", pinyin: "yinchuan", airport_code: "INC", region: "宁夏", is_hot: false, themes: [] },
  { name: "中卫市", pinyin: "zhongwei", airport_code: "ZHY", region: "宁夏", is_hot: false, themes: [] },
  { name: "固原市", pinyin: "guyuan", airport_code: "GYU", region: "宁夏", is_hot: false, themes: [] },
  
  # 青海省
  { name: "西宁市", pinyin: "xining", airport_code: "XNN", region: "青海", is_hot: false, themes: [] },
  { name: "格尔木市", pinyin: "geermu", airport_code: "GOQ", region: "青海", is_hot: false, themes: [] },
  { name: "德令哈市", pinyin: "delingha", airport_code: "HXD", region: "青海", is_hot: false, themes: [] },
  
  # 甘肃省
  { name: "兰州市", pinyin: "lanzhou", airport_code: "LHW", region: "甘肃", is_hot: false, themes: [] },
  { name: "敦煌市", pinyin: "dunhuang", airport_code: "DNH", region: "甘肃", is_hot: false, themes: [] },
  { name: "嘉峪关市", pinyin: "jiayuguan", airport_code: "JGN", region: "甘肃", is_hot: false, themes: [] },
  
  # 特别行政区
  { name: "香港", pinyin: "xianggang", airport_code: "HKG", region: "香港", is_hot: true, themes: ["热门目的地", "亲子必去"] },
  { name: "澳门", pinyin: "aomen", airport_code: "MFM", region: "澳门", is_hot: true, themes: ["热门目的地"] },
  
  # 台湾省
  { name: "台北", pinyin: "taibei", airport_code: "TPE", region: "台湾", is_hot: false, themes: [] },
  { name: "高雄", pinyin: "gaoxiong", airport_code: "KHH", region: "台湾", is_hot: false, themes: [] },
  { name: "台中", pinyin: "taizhong", airport_code: "RMQ", region: "台湾", is_hot: false, themes: [] },

  # 日本
  { name: "东京", pinyin: "dongjing", airport_code: "NRT", region: "日本", is_hot: true, themes: ["热门目的地", "亲子必去"] },
  { name: "大阪", pinyin: "daban", airport_code: "KIX", region: "日本", is_hot: true, themes: ["热门目的地", "亲子必去"] },
  { name: "京都", pinyin: "jingdu", airport_code: "KIX", region: "日本", is_hot: false, themes: ["亲子必去"] },
  { name: "札幌", pinyin: "zhahuan", airport_code: "CTS", region: "日本", is_hot: false, themes: [] },
  { name: "福冈", pinyin: "fugang", airport_code: "FUK", region: "日本", is_hot: false, themes: [] },
  { name: "冲绳", pinyin: "chongsheng", airport_code: "OKA", region: "日本", is_hot: false, themes: ["海边度假"] },

  # 韩国
  { name: "首尔", pinyin: "shouer", airport_code: "ICN", region: "韩国", is_hot: true, themes: ["热门目的地", "亲子必去"] },
  { name: "济州岛", pinyin: "jizhoudao", airport_code: "CJU", region: "韩国", is_hot: true, themes: ["海边度假", "热门目的地"] },
  { name: "釜山", pinyin: "fushan", airport_code: "PUS", region: "韩国", is_hot: false, themes: ["海边度假"] },

  # 泰国
  { name: "曼谷", pinyin: "mangu", airport_code: "BKK", region: "泰国", is_hot: true, themes: ["热门目的地", "亲子必去"] },
  { name: "清迈", pinyin: "qingmai", airport_code: "CNX", region: "泰国", is_hot: false, themes: [] },
  { name: "普吉岛", pinyin: "pujidao", airport_code: "HKT", region: "泰国", is_hot: true, themes: ["海边度假", "热门目的地"] },
  { name: "芭提雅", pinyin: "batiya", airport_code: "BKK", region: "泰国", is_hot: false, themes: ["海边度假"] },

  # 马来西亚
  { name: "吉隆坡", pinyin: "jilongpo", airport_code: "KUL", region: "马来西亚", is_hot: true, themes: ["热门目的地"] },
  { name: "槟城", pinyin: "bincheng", airport_code: "PEN", region: "马来西亚", is_hot: false, themes: ["海边度假"] },

  # 新加坡
  { name: "新加坡", pinyin: "xinjiapo", airport_code: "SIN", region: "新加坡", is_hot: true, themes: ["热门目的地", "亲子必去"] },

  # 越南
  { name: "胡志明", pinyin: "huzhiming", airport_code: "SGN", region: "越南", is_hot: false, themes: [] },
  { name: "河内", pinyin: "henei", airport_code: "HAN", region: "越南", is_hot: false, themes: [] },
  { name: "芽庄", pinyin: "yazhuang", airport_code: "CXR", region: "越南", is_hot: false, themes: ["海边度假"] },

  # 欧洲
  { name: "伦敦", pinyin: "lundun", airport_code: "LHR", region: "英国", is_hot: true, themes: ["热门目的地"] },
  { name: "巴黎", pinyin: "bali", airport_code: "CDG", region: "法国", is_hot: true, themes: ["热门目的地"] },
  { name: "罗马", pinyin: "luoma", airport_code: "FCO", region: "意大利", is_hot: true, themes: ["热门目的地"] },
  { name: "巴塞罗那", pinyin: "basailuona", airport_code: "BCN", region: "西班牙", is_hot: false, themes: [] },
  { name: "阿姆斯特丹", pinyin: "amusitedan", airport_code: "AMS", region: "荷兰", is_hot: false, themes: [] },
  { name: "慕尼黑", pinyin: "munihei", airport_code: "MUC", region: "德国", is_hot: false, themes: [] },

  # 美洲
  { name: "纽约", pinyin: "niuyue", airport_code: "JFK", region: "美国", is_hot: true, themes: ["热门目的地"] },
  { name: "洛杉矶", pinyin: "luoshanji", airport_code: "LAX", region: "美国", is_hot: true, themes: ["热门目的地"] },
  { name: "旧金山", pinyin: "jiujinshan", airport_code: "SFO", region: "美国", is_hot: false, themes: [] },
  { name: "多伦多", pinyin: "duolunduo", airport_code: "YYZ", region: "加拿大", is_hot: false, themes: [] },
  { name: "温哥华", pinyin: "wengehua", airport_code: "YVR", region: "加拿大", is_hot: false, themes: [] },

  # 大洋洲
  { name: "悉尼", pinyin: "xini", airport_code: "SYD", region: "澳大利亚", is_hot: true, themes: ["热门目的地", "海边度假"] },
  { name: "墨尔本", pinyin: "moerben", airport_code: "MEL", region: "澳大利亚", is_hot: false, themes: [] },
  { name: "奥克兰", pinyin: "aokeland", airport_code: "AKL", region: "新西兰", is_hot: false, themes: [] },

  # 中东
  { name: "迪拜", pinyin: "dibai", airport_code: "DXB", region: "阿联酋", is_hot: true, themes: ["热门目的地"] },
  { name: "伊斯坦布尔", pinyin: "yisitanbuer", airport_code: "IST", region: "土耳其", is_hot: false, themes: [] },

  # 非洲
  { name: "开罗", pinyin: "kailuo", airport_code: "CAI", region: "埃及", is_hot: false, themes: [] },
  { name: "内罗毕", pinyin: "neiluobi", airport_code: "NBO", region: "肯尼亚", is_hot: false, themes: [] }
]

# 批量插入优化：使用 Rails 原生 insert_all
existing_cities = City.pluck(:name).to_set
new_cities_data = cities_data.reject { |data| existing_cities.include?(data[:name]) }

if new_cities_data.any?
  timestamp = Time.current
  cities_with_timestamps = new_cities_data.map do |data|
    data.merge(created_at: timestamp, updated_at: timestamp)
  end
  
  City.insert_all(cities_with_timestamps)
  puts "     批量创建了 #{new_cities_data.size} 个新城市"
else
  puts "     所有城市已存在，跳过创建"
end

puts "     城市总数: #{City.count}"

# ==================== 目的地数据 ====================
puts "  → 正在加载目的地数据..."

# 清理旧数据（如果需要重新加载）
# TourProduct.destroy_all
# Destination.destroy_all

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

# 批量插入热门目的地
existing_destinations = Destination.pluck(:name).to_set
new_destinations_data = destinations_data.reject { |data| existing_destinations.include?(data[:name]) }

if new_destinations_data.any?
  timestamp = Time.current
  destinations_with_timestamps = new_destinations_data.map do |data|
    data.merge(created_at: timestamp, updated_at: timestamp)
  end
  
  Destination.insert_all(destinations_with_timestamps)
  puts "     批量创建了 #{new_destinations_data.size} 个热门目的地"
else
  puts "     所有热门目的地已存在，跳过创建"
end

# 批量为城市创建 Destination 记录
existing_destinations = Destination.pluck(:name).to_set
auto_destinations_data = []

City.find_each do |city|
  next if existing_destinations.include?(city.name)
  
  auto_destinations_data << {
    name: city.name,
    region: city.region,
    is_hot: city.is_hot,
    description: "探索#{city.name}的美好",
    created_at: Time.current,
    updated_at: Time.current
  }
end

if auto_destinations_data.any?
  Destination.insert_all(auto_destinations_data)
  puts "     为城市批量创建了 #{auto_destinations_data.size} 个 Destination 记录"
else
  puts "     所有城市的 Destination 已存在，跳过创建"
end

puts "     Destination 总数: #{Destination.count}"

puts "\n✓ base_v1 数据包加载完成"
puts "  - 城市: #{City.count} 个"
puts "  - 目的地: #{Destination.count} 个"
