# frozen_string_literal: true

# 加载 activerecord-import gem
require 'activerecord-import' unless defined?(ActiveRecord::Import)

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
  { name: "嘉兴", pinyin: "jiaxing", airport_code: "HGH", region: "浙江", is_hot: false, themes: [] },
  { name: "湖州", pinyin: "huzhou", airport_code: "HGH", region: "浙江", is_hot: false, themes: [] },
  { name: "绍兴", pinyin: "shaoxing", airport_code: "HGH", region: "浙江", is_hot: false, themes: [] },
  { name: "金华", pinyin: "jinhua", airport_code: "YIW", region: "浙江", is_hot: false, themes: [] },
  { name: "衢州", pinyin: "quzhou", airport_code: "JUZ", region: "浙江", is_hot: false, themes: [] },
  { name: "丽水", pinyin: "lishui", airport_code: "LYI", region: "浙江", is_hot: false, themes: [] },
  
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
  { name: "绵阳", pinyin: "mianyang", airport_code: "MIG", region: "四川", is_hot: false, themes: [] },
  { name: "德阳", pinyin: "deyang", airport_code: "CTU", region: "四川", is_hot: false, themes: [] },
  { name: "广元", pinyin: "guangyuan", airport_code: "GYS", region: "四川", is_hot: false, themes: [] },
  { name: "遂宁", pinyin: "suining", airport_code: "CTU", region: "四川", is_hot: false, themes: [] },
  { name: "内江", pinyin: "neijiang", airport_code: "CTU", region: "四川", is_hot: false, themes: [] },
  { name: "宜宾", pinyin: "yibin", airport_code: "YBP", region: "四川", is_hot: false, themes: [] },
  { name: "南充", pinyin: "nanchong", airport_code: "NAO", region: "四川", is_hot: false, themes: [] },
  { name: "达州", pinyin: "dazhou", airport_code: "DAX", region: "四川", is_hot: false, themes: [] },
  { name: "泸州", pinyin: "luzhou", airport_code: "LZO", region: "四川", is_hot: false, themes: [] },
  { name: "广安", pinyin: "guangan", airport_code: "GAX", region: "四川", is_hot: false, themes: [] },
  { name: "巴中", pinyin: "bazhong", airport_code: "BZX", region: "四川", is_hot: false, themes: [] },
  { name: "雅安", pinyin: "yaan", airport_code: "CTU", region: "四川", is_hot: false, themes: [] },
  { name: "眉山", pinyin: "meishan", airport_code: "CTU", region: "四川", is_hot: false, themes: [] },
  { name: "资阳", pinyin: "ziyang", airport_code: "CTU", region: "四川", is_hot: false, themes: [] },
  { name: "阿坝", pinyin: "aba", airport_code: "JZH", region: "四川", is_hot: false, themes: [] },
  { name: "甘孜", pinyin: "ganzi", airport_code: "KGT", region: "四川", is_hot: false, themes: [] },
  { name: "凉山", pinyin: "liangshan", airport_code: "XIC", region: "四川", is_hot: false, themes: [] },
  { name: "攻坳花", pinyin: "panzhihua", airport_code: "PZI", region: "四川", is_hot: false, themes: [] },
  
  # 陕西省
  { name: "西安", pinyin: "xian", airport_code: "XIY", region: "陕西", is_hot: true, themes: ["热门目的地", "亲子必去"] },
  { name: "延安", pinyin: "yanan", airport_code: "ENY", region: "陕西", is_hot: false, themes: [] },
  { name: "汉中", pinyin: "hanzhong", airport_code: "HZG", region: "陕西", is_hot: false, themes: [] },
  
  # 湖北省
  { name: "武汉", pinyin: "wuhan", airport_code: "WUH", region: "湖北", is_hot: true, themes: ["热门目的地"] },
  { name: "宜昌", pinyin: "yichang", airport_code: "YIH", region: "湖北", is_hot: false, themes: [] },
  { name: "襄阳", pinyin: "xiangyang", airport_code: "XFN", region: "湖北", is_hot: false, themes: [] },
  { name: "荆州", pinyin: "jingzhou", airport_code: "SHS", region: "湖北", is_hot: false, themes: [] },
  { name: "黄石", pinyin: "huangshi", airport_code: "WUH", region: "湖北", is_hot: false, themes: [] },
  { name: "荆门", pinyin: "jingmen", airport_code: "JM1", region: "湖北", is_hot: false, themes: [] },
  { name: "十堰", pinyin: "shiyan", airport_code: "WDS", region: "湖北", is_hot: false, themes: [] },
  { name: "孝感", pinyin: "xiaogan", airport_code: "WUH", region: "湖北", is_hot: false, themes: [] },
  { name: "黄冈", pinyin: "huanggang", airport_code: "WUH", region: "湖北", is_hot: false, themes: [] },
  { name: "咸宁", pinyin: "xianning", airport_code: "WUH", region: "湖北", is_hot: false, themes: [] },
  { name: "随州", pinyin: "suizhou", airport_code: "WUH", region: "湖北", is_hot: false, themes: [] },
  { name: "恩施", pinyin: "enshi", airport_code: "ENH", region: "湖北", is_hot: false, themes: [] },
  { name: "仙桃", pinyin: "xiantao", airport_code: "WUH", region: "湖北", is_hot: false, themes: [] },
  { name: "潜江", pinyin: "qianjiang", airport_code: "WUH", region: "湖北", is_hot: false, themes: [] },
  { name: "天门", pinyin: "tianmen", airport_code: "WUH", region: "湖北", is_hot: false, themes: [] },
  
  # 湖南省
  { name: "长沙", pinyin: "changsha", airport_code: "CSX", region: "湖南", is_hot: false, themes: [] },
  { name: "张家界", pinyin: "zhangjiajie", airport_code: "DYG", region: "湖南", is_hot: false, themes: [] },
  { name: "凤凰", pinyin: "fenghuang", airport_code: "TEN", region: "湖南", is_hot: false, themes: [] },
  { name: "株洲", pinyin: "zhuzhou", airport_code: "CSX", region: "湖南", is_hot: false, themes: [] },
  { name: "湘潭", pinyin: "xiangtan", airport_code: "CSX", region: "湖南", is_hot: false, themes: [] },
  { name: "衡阳", pinyin: "hengyang", airport_code: "HNY", region: "湖南", is_hot: false, themes: [] },
  { name: "邵阳", pinyin: "shaoyang", airport_code: "WGN", region: "湖南", is_hot: false, themes: [] },
  { name: "岳阳", pinyin: "yueyang", airport_code: "YYA", region: "湖南", is_hot: false, themes: [] },
  { name: "常德", pinyin: "changde", airport_code: "CGD", region: "湖南", is_hot: false, themes: [] },
  { name: "益阳", pinyin: "yiyang", airport_code: "CSX", region: "湖南", is_hot: false, themes: [] },
  { name: "郴州", pinyin: "chenzhou", airport_code: "HCZ", region: "湖南", is_hot: false, themes: [] },
  { name: "永州", pinyin: "yongzhou", airport_code: "LLF", region: "湖南", is_hot: false, themes: [] },
  { name: "怀化", pinyin: "huaihua", airport_code: "HJJ", region: "湖南", is_hot: false, themes: [] },
  { name: "娄底", pinyin: "loudi", airport_code: "CSX", region: "湖南", is_hot: false, themes: [] },
  { name: "湘西", pinyin: "xiangxi", airport_code: "DYG", region: "湖南", is_hot: false, themes: [] },
  
  # 福建省
  { name: "厦门", pinyin: "xiamen", airport_code: "XMN", region: "福建", is_hot: true, themes: ["热门目的地", "海边度假", "亲子必去"] },
  { name: "福州", pinyin: "fuzhou", airport_code: "FOC", region: "福建", is_hot: false, themes: ["海边度假"] },
  { name: "泉州", pinyin: "quanzhou", airport_code: "JJN", region: "福建", is_hot: false, themes: ["海边度假"] },
  { name: "平潭", pinyin: "pingtan", airport_code: "FOC", region: "福建", is_hot: false, themes: ["海边度假"] },
  { name: "漳州", pinyin: "zhangzhou", airport_code: "XMN", region: "福建", is_hot: false, themes: ["海边度假"] },
  { name: "莆田", pinyin: "putian", airport_code: "FOC", region: "福建", is_hot: false, themes: ["海边度假"] },
  { name: "三明", pinyin: "sanming", airport_code: "SQJ", region: "福建", is_hot: false, themes: [] },
  { name: "龙岩", pinyin: "longyan", airport_code: "LCX", region: "福建", is_hot: false, themes: [] },
  { name: "宁德", pinyin: "ningde", airport_code: "FOC", region: "福建", is_hot: false, themes: ["海边度假"] },
  { name: "南平", pinyin: "nanping", airport_code: "WUS", region: "福建", is_hot: false, themes: [] },
  
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
  { name: "大庆", pinyin: "daqing", airport_code: "DQA", region: "黑龙江", is_hot: false, themes: [] },
  { name: "佳木斯", pinyin: "jiamusi", airport_code: "JMU", region: "黑龙江", is_hot: false, themes: [] },
  { name: "鸡西", pinyin: "jixi", airport_code: "JXA", region: "黑龙江", is_hot: false, themes: [] },
  { name: "双鸭山", pinyin: "shuangyashan", airport_code: "JMU", region: "黑龙江", is_hot: false, themes: [] },
  { name: "伊春", pinyin: "yichun", airport_code: "LDS", region: "黑龙江", is_hot: false, themes: [] },
  { name: "七台河", pinyin: "qitaihe", airport_code: "JXA", region: "黑龙江", is_hot: false, themes: [] },
  { name: "鹤岗", pinyin: "hegang", airport_code: "HEK", region: "黑龙江", is_hot: false, themes: [] },
  { name: "黑河", pinyin: "heihe", airport_code: "HEK", region: "黑龙江", is_hot: false, themes: [] },
  { name: "绥化", pinyin: "suihua", airport_code: "HRB", region: "黑龙江", is_hot: false, themes: [] },
  
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
  { name: "曲靖", pinyin: "qujing", airport_code: "KMG", region: "云南", is_hot: false, themes: [] },
  { name: "玉溪", pinyin: "yuxi", airport_code: "KMG", region: "云南", is_hot: false, themes: [] },
  { name: "保山", pinyin: "baoshan", airport_code: "BSD", region: "云南", is_hot: false, themes: [] },
  { name: "昭通", pinyin: "zhaotong", airport_code: "ZAT", region: "云南", is_hot: false, themes: [] },
  { name: "临沧", pinyin: "lincang", airport_code: "LNJ", region: "云南", is_hot: false, themes: [] },
  { name: "普洱", pinyin: "puer", airport_code: "SYM", region: "云南", is_hot: false, themes: [] },
  { name: "楚雄", pinyin: "chuxiong", airport_code: "KMG", region: "云南", is_hot: false, themes: [] },
  { name: "红河", pinyin: "honghe", airport_code: "MIG", region: "云南", is_hot: false, themes: [] },
  { name: "文山", pinyin: "wenshan", airport_code: "WNH", region: "云南", is_hot: false, themes: [] },
  { name: "德宏", pinyin: "dehong", airport_code: "LUM", region: "云南", is_hot: false, themes: [] },
  { name: "怒江", pinyin: "nujiang", airport_code: "BSD", region: "云南", is_hot: false, themes: [] },
  
  # 贵州省
  { name: "贵阳", pinyin: "guiyang", airport_code: "KWE", region: "贵州", is_hot: false, themes: [] },
  { name: "安顺", pinyin: "anshun", airport_code: "AVA", region: "贵州", is_hot: false, themes: [] },
  { name: "凯里", pinyin: "kaili", airport_code: "KWE", region: "贵州", is_hot: false, themes: [] },
  { name: "遵义", pinyin: "zunyi", airport_code: "ZYI", region: "贵州", is_hot: false, themes: [] },
  { name: "铜仁", pinyin: "tongren", airport_code: "TEN", region: "贵州", is_hot: false, themes: [] },
  { name: "毕节", pinyin: "bijie", airport_code: "BFJ", region: "贵州", is_hot: false, themes: [] },
  { name: "六盘水", pinyin: "liupanshui", airport_code: "LPF", region: "贵州", is_hot: false, themes: [] },
  { name: "黔西南", pinyin: "qianxinan", airport_code: "ACX", region: "贵州", is_hot: false, themes: [] },
  { name: "黔东南", pinyin: "qiandongnan", airport_code: "KJH", region: "贵州", is_hot: false, themes: [] },
  { name: "黔南", pinyin: "qiannan", airport_code: "KWE", region: "贵州", is_hot: false, themes: [] },
  
  # 山西省
  { name: "太原", pinyin: "taiyuan", airport_code: "TYN", region: "山西", is_hot: false, themes: [] },
  { name: "大同", pinyin: "datong", airport_code: "DAT", region: "山西", is_hot: false, themes: [] },
  { name: "平遥", pinyin: "pingyao", airport_code: "TYN", region: "山西", is_hot: false, themes: [] },
  
  # 河北省
  { name: "石家庄", pinyin: "shijiazhuang", airport_code: "SJW", region: "河北", is_hot: false, themes: [] },
  { name: "秦皇岛", pinyin: "qinhuangdao", airport_code: "SHP", region: "河北", is_hot: false, themes: ["海边度假"] },
  { name: "承德", pinyin: "chengde", airport_code: "CDE", region: "河北", is_hot: false, themes: [] },
  { name: "唐山", pinyin: "tangshan", airport_code: "TVS", region: "河北", is_hot: false, themes: ["海边度假"] },
  { name: "保定", pinyin: "baoding", airport_code: "SJW", region: "河北", is_hot: false, themes: [] },
  { name: "张家口", pinyin: "zhangjiakou", airport_code: "ZQZ", region: "河北", is_hot: false, themes: [] },
  { name: "廊坊", pinyin: "langfang", airport_code: "PEK", region: "河北", is_hot: false, themes: [] },
  { name: "沧州", pinyin: "cangzhou", airport_code: "SJW", region: "河北", is_hot: false, themes: [] },
  { name: "衡水", pinyin: "hengshui", airport_code: "SJW", region: "河北", is_hot: false, themes: [] },
  { name: "邢台", pinyin: "xingtai", airport_code: "XNT", region: "河北", is_hot: false, themes: [] },
  { name: "邯郸", pinyin: "handan", airport_code: "HDG", region: "河北", is_hot: false, themes: [] },
  
  # 河南省
  { name: "郑州", pinyin: "zhengzhou", airport_code: "CGO", region: "河南", is_hot: false, themes: [] },
  { name: "洛阳", pinyin: "luoyang", airport_code: "LYA", region: "河南", is_hot: false, themes: [] },
  { name: "开封", pinyin: "kaifeng", airport_code: "CGO", region: "河南", is_hot: false, themes: [] },
  { name: "南阳", pinyin: "nanyang", airport_code: "NNY", region: "河南", is_hot: false, themes: [] },
  { name: "安阳", pinyin: "anyang", airport_code: "AYN", region: "河南", is_hot: false, themes: [] },
  { name: "新乡", pinyin: "xinxiang", airport_code: "CGO", region: "河南", is_hot: false, themes: [] },
  { name: "平顶山", pinyin: "pingdingshan", airport_code: "CGO", region: "河南", is_hot: false, themes: [] },
  { name: "焦作", pinyin: "jiaozuo", airport_code: "CGO", region: "河南", is_hot: false, themes: [] },
  { name: "许昌", pinyin: "xuchang", airport_code: "CGO", region: "河南", is_hot: false, themes: [] },
  { name: "信阳", pinyin: "xinyang", airport_code: "XAI", region: "河南", is_hot: false, themes: [] },
  { name: "商丘", pinyin: "shangqiu", airport_code: "SQJ", region: "河南", is_hot: false, themes: [] },
  { name: "周口", pinyin: "zhoukou", airport_code: "CGO", region: "河南", is_hot: false, themes: [] },
  { name: "驻马店", pinyin: "zhumadian", airport_code: "CGO", region: "河南", is_hot: false, themes: [] },
  { name: "濮阳", pinyin: "puyang", airport_code: "CGO", region: "河南", is_hot: false, themes: [] },
  { name: "三门峡", pinyin: "sanmenxia", airport_code: "SHX", region: "河南", is_hot: false, themes: [] },
  { name: "鹤壁", pinyin: "hebi", airport_code: "CGO", region: "河南", is_hot: false, themes: [] },
  { name: "漯河", pinyin: "luohe", airport_code: "CGO", region: "河南", is_hot: false, themes: [] },
  
  # 安徽省
  { name: "合肥", pinyin: "hefei", airport_code: "HFE", region: "安徽", is_hot: false, themes: [] },
  { name: "黄山", pinyin: "huangshan", airport_code: "TXN", region: "安徽", is_hot: false, themes: [] },
  { name: "芜湖", pinyin: "wuhu", airport_code: "WHU", region: "安徽", is_hot: false, themes: [] },
  { name: "蚌埠", pinyin: "bengbu", airport_code: "HFE", region: "安徽", is_hot: false, themes: [] },
  { name: "马鞍山", pinyin: "maanshan", airport_code: "NKG", region: "安徽", is_hot: false, themes: [] },
  { name: "铜陵", pinyin: "tongling", airport_code: "HFE", region: "安徽", is_hot: false, themes: [] },
  { name: "安庆", pinyin: "anqing", airport_code: "AQG", region: "安徽", is_hot: false, themes: [] },
  { name: "滁州", pinyin: "chuzhou", airport_code: "HFE", region: "安徽", is_hot: false, themes: [] },
  { name: "阜阳", pinyin: "fuyang", airport_code: "FUG", region: "安徽", is_hot: false, themes: [] },
  { name: "宿州", pinyin: "suzhou", airport_code: "HFE", region: "安徽", is_hot: false, themes: [] },
  { name: "六安", pinyin: "luan", airport_code: "HFE", region: "安徽", is_hot: false, themes: [] },
  { name: "亳州", pinyin: "bozhou", airport_code: "FUG", region: "安徽", is_hot: false, themes: [] },
  { name: "池州", pinyin: "chizhou", airport_code: "JUH", region: "安徽", is_hot: false, themes: [] },
  { name: "宣城", pinyin: "xuancheng", airport_code: "HFE", region: "安徽", is_hot: false, themes: [] },
  { name: "淮南", pinyin: "huainan", airport_code: "HFE", region: "安徽", is_hot: false, themes: [] },
  { name: "淮北", pinyin: "huaibei", airport_code: "HFE", region: "安徽", is_hot: false, themes: [] },
  
  # 江西省
  { name: "南昌", pinyin: "nanchang", airport_code: "KHN", region: "江西", is_hot: false, themes: [] },
  { name: "景德镇", pinyin: "jingdezhen", airport_code: "JDZ", region: "江西", is_hot: false, themes: [] },
  { name: "九江", pinyin: "jiujiang", airport_code: "JIU", region: "江西", is_hot: false, themes: [] },
  { name: "赣州", pinyin: "ganzhou", airport_code: "KOW", region: "江西", is_hot: false, themes: [] },
  { name: "上饶", pinyin: "shangrao", airport_code: "SQD", region: "江西", is_hot: false, themes: [] },
  { name: "宜春", pinyin: "yichun", airport_code: "KHN", region: "江西", is_hot: false, themes: [] },
  { name: "抚州", pinyin: "fuzhou", airport_code: "KHN", region: "江西", is_hot: false, themes: [] },
  { name: "吉安", pinyin: "jian", airport_code: "JGS", region: "江西", is_hot: false, themes: [] },
  { name: "鹰潭", pinyin: "yingtan", airport_code: "KHN", region: "江西", is_hot: false, themes: [] },
  { name: "新余", pinyin: "xinyu", airport_code: "KHN", region: "江西", is_hot: false, themes: [] },
  { name: "萍乡", pinyin: "pingxiang", airport_code: "KHN", region: "江西", is_hot: false, themes: [] },
  
  # 广西省
  { name: "南宁", pinyin: "nanning", airport_code: "NNG", region: "广西", is_hot: false, themes: [] },
  { name: "桂林", pinyin: "guilin", airport_code: "KWL", region: "广西", is_hot: false, themes: [] },
  { name: "北海", pinyin: "beihai", airport_code: "BHY", region: "广西", is_hot: false, themes: ["海边度假"] },
  { name: "防城港", pinyin: "fangchenggang", airport_code: "BHY", region: "广西", is_hot: false, themes: ["海边度假"] },
  { name: "柳州", pinyin: "liuzhou", airport_code: "LZH", region: "广西", is_hot: false, themes: [] },
  { name: "梧州", pinyin: "wuzhou", airport_code: "WUZ", region: "广西", is_hot: false, themes: [] },
  { name: "贵港", pinyin: "guigang", airport_code: "NNG", region: "广西", is_hot: false, themes: [] },
  { name: "玉林", pinyin: "yulin", airport_code: "NNG", region: "广西", is_hot: false, themes: [] },
  { name: "百色", pinyin: "baise", airport_code: "AEB", region: "广西", is_hot: false, themes: [] },
  { name: "贺州", pinyin: "hezhou", airport_code: "NNG", region: "广西", is_hot: false, themes: [] },
  { name: "河池", pinyin: "hechi", airport_code: "HCJ", region: "广西", is_hot: false, themes: [] },
  { name: "来宾", pinyin: "laibin", airport_code: "NNG", region: "广西", is_hot: false, themes: [] },
  { name: "崇左", pinyin: "chongzuo", airport_code: "NNG", region: "广西", is_hot: false, themes: [] },
  { name: "钦州", pinyin: "qinzhou", airport_code: "BHY", region: "广西", is_hot: false, themes: ["海边度假"] },
  
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

# 确保 City 模型的 schema 信息是最新的
City.reset_column_information

# 批量插入优化：使用 Rails 原生 insert_all
existing_cities = City.pluck(:name).to_set
new_cities_data = cities_data.reject { |data| existing_cities.include?(data[:name]) }

if new_cities_data.any?
  timestamp = Time.current
  cities_with_timestamps = new_cities_data.map do |data|
    data.merge(created_at: timestamp, updated_at: timestamp)
  end
  
  City.insert_all(cities_with_timestamps)
else
  puts "     所有城市已存在，跳过创建"
end

puts "     城市总数: #{City.count}"

# ==================== 目的地数据 ====================

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
else
  puts "     所有城市的 Destination 已存在，跳过创建"
end

puts "     Destination 总数: #{Destination.count}"

puts "  - 城市: #{City.count} 个"
puts "  - 目的地: #{Destination.count} 个"
