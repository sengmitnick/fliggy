# frozen_string_literal: true

puts "正在加载签证服务数据..."

# 韩国签证服务
VisaService.create!([
  {
    title: "韩国·团体旅游签证·全国送签·官方直营·韩国自由行【只需护照】5-8工作日出签",
    country: "韩国",
    service_type: "全国送签",
    success_rate: 100.0,
    processing_days: 5,
    price: 108,
    original_price: 113,
    urgent_processing: false,
    description: "韩国团体旅游签证，全国送签，只需护照，5-8工作日出签",
    merchant_name: "湖南新康辉国旅旗舰店",
    sales_count: 700,
    image_url: "https://images.unsplash.com/photo-1517154421773-0529f29ea451?w=400"
  },
  {
    title: "韩国·单次签证·武汉送签·韩国个人旅游单次签证武汉领区河南湖南湖北江西",
    country: "韩国",
    service_type: "武汉送签",
    success_rate: 97.8,
    processing_days: 8,
    price: 433,
    original_price: 438,
    urgent_processing: false,
    description: "韩国单次签证，武汉送签，覆盖河南湖南湖北江西",
    merchant_name: "武汉碧海蓝天旅游专营店",
    sales_count: 1000,
    image_url: "https://images.unsplash.com/photo-1583474439862-d2fd6d7a19e7?w=400"
  },
  {
    title: "韩国·单次签证·武汉送签·韩国签证个人旅游单次签证五年多次简化学生商务加急",
    country: "韩国",
    service_type: "武汉送签",
    success_rate: 99.3,
    processing_days: 10,
    price: 448,
    original_price: 453,
    urgent_processing: true,
    description: "韩国签证，支持五年多次，简化流程，加急办理",
    merchant_name: "湖北倾迷旅行社专营店",
    sales_count: 1000,
    image_url: "https://images.unsplash.com/photo-1532175402170-0ce0e1d850b7?w=400"
  }
])

# 日本签证服务
VisaService.create!([
  {
    title: "日本·单次旅游签证·北京送签·【出签简单 拒签全退】个人旅游自由行在留简化签证",
    country: "日本",
    service_type: "北京送签",
    success_rate: 100.0,
    processing_days: 18,
    price: 191,
    original_price: 196,
    urgent_processing: false,
    description: "日本单次旅游签证，出签简单，拒签全退，个人旅游自由行",
    merchant_name: "湖南宝中旅行社专营店",
    sales_count: 600,
    image_url: "https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=400"
  },
  {
    title: "日本·单次旅游签证·北京送签·【拒一赔三】加急办理电子签证简化学生商务多次往返",
    country: "日本",
    service_type: "北京送签",
    success_rate: 100.0,
    processing_days: 10,
    price: 448,
    original_price: 453,
    urgent_processing: true,
    description: "日本签证加急办理，拒一赔三，电子签证简化流程",
    merchant_name: "中国旅行社总社湖南专营店",
    sales_count: 1000,
    image_url: "https://images.unsplash.com/photo-1528164344705-47542687000d?w=400"
  },
  {
    title: "日本·三年多次签证·北京送签·冲绳/东北三县首次必访·免在留·简化材料",
    country: "日本",
    service_type: "北京送签",
    success_rate: 98.5,
    processing_days: 15,
    price: 588,
    original_price: 598,
    urgent_processing: false,
    description: "日本三年多次签证，冲绳/东北三县首次必访，免在留，简化材料",
    merchant_name: "湖南宝中旅行社专营店",
    sales_count: 350,
    image_url: "https://images.unsplash.com/photo-1542640244-7e672d6cef4e?w=400"
  },
  {
    title: "日本·五年多次签证·北京送签·简化办理·免在留·高出签率·全国受理",
    country: "日本",
    service_type: "北京送签",
    success_rate: 96.2,
    processing_days: 20,
    price: 788,
    original_price: 798,
    urgent_processing: false,
    description: "日本五年多次签证，简化办理，免在留，高出签率，全国受理",
    merchant_name: "中国旅行社总社湖南专营店",
    sales_count: 280,
    image_url: "https://images.unsplash.com/photo-1480796927426-f609979314bd?w=400"
  }
])

# 泰国签证服务
VisaService.create!([
  {
    title: "泰国·旅游签证·全国送签·【1-2工作日极速出签】代办泰国签证个人旅游自由行",
    country: "泰国",
    service_type: "全国送签",
    success_rate: 100.0,
    processing_days: 2,
    price: 88,
    original_price: 93,
    urgent_processing: true,
    description: "泰国旅游签证，1-2工作日极速出签，代办个人旅游自由行",
    merchant_name: "湖南新康辉国旅旗舰店",
    sales_count: 1500,
    image_url: "https://images.unsplash.com/photo-1552465011-b4e21bf6e79a?w=400"
  },
  {
    title: "泰国·电子签证·全国办理·【3工作日出签】泰国电子签证在线办理eVisa",
    country: "泰国",
    service_type: "全国送签",
    success_rate: 99.8,
    processing_days: 3,
    price: 158,
    original_price: 163,
    urgent_processing: false,
    description: "泰国电子签证，3工作日出签，在线办理eVisa",
    merchant_name: "武汉碧海蓝天旅游专营店",
    sales_count: 980,
    image_url: "https://images.unsplash.com/photo-1528181304800-259b08848526?w=400"
  }
])

# 新加坡签证服务
VisaService.create!([
  {
    title: "新加坡·电子签证·全国送签·【极速2-3工作日】新加坡签证个人旅游63天电子签",
    country: "新加坡",
    service_type: "全国送签",
    success_rate: 100.0,
    processing_days: 3,
    price: 268,
    original_price: 278,
    urgent_processing: true,
    description: "新加坡电子签证，极速2-3工作日，63天有效期",
    merchant_name: "湖南宝中旅行社专营店",
    sales_count: 850,
    image_url: "https://images.unsplash.com/photo-1525625293386-3f8f99389edd?w=400"
  },
  {
    title: "新加坡·两年多次签证·全国送签·简化材料·高出签率·商务旅游通用",
    country: "新加坡",
    service_type: "全国送签",
    success_rate: 98.5,
    processing_days: 5,
    price: 388,
    original_price: 398,
    urgent_processing: false,
    description: "新加坡两年多次签证，简化材料，高出签率，商务旅游通用",
    merchant_name: "中国旅行社总社湖南专营店",
    sales_count: 520,
    image_url: "https://images.unsplash.com/photo-1565967511849-76a60a516170?w=400"
  }
])

# 马来西亚签证服务
VisaService.create!([
  {
    title: "马来西亚·电子签证·全国办理·【24小时极速出签】马来西亚eVISA电子签证",
    country: "马来西亚",
    service_type: "全国送签",
    success_rate: 100.0,
    processing_days: 1,
    price: 128,
    original_price: 133,
    urgent_processing: true,
    description: "马来西亚电子签证，24小时极速出签，eVISA电子签证",
    merchant_name: "湖南新康辉国旅旗舰店",
    sales_count: 1200,
    image_url: "https://images.unsplash.com/photo-1596422846543-75c6fc197f07?w=400"
  }
])

# 越南签证服务
VisaService.create!([
  {
    title: "越南·电子签证·全国办理·【1工作日出签】越南签证个人旅游eVISA电子签",
    country: "越南",
    service_type: "全国送签",
    success_rate: 100.0,
    processing_days: 1,
    price: 68,
    original_price: 73,
    urgent_processing: true,
    description: "越南电子签证，1工作日出签，个人旅游eVISA",
    merchant_name: "武汉碧海蓝天旅游专营店",
    sales_count: 1800,
    image_url: "https://images.unsplash.com/photo-1583417319070-4a69db38a482?w=400"
  }
])

puts "✓ 签证服务数据加载完成！"
puts "  - 韩国签证: 3 个商品"
puts "  - 日本签证: 4 个商品"
puts "  - 泰国签证: 2 个商品"
puts "  - 新加坡签证: 2 个商品"
puts "  - 马来西亚签证: 1 个商品"
puts "  - 越南签证: 1 个商品"
puts "  总计: #{VisaService.count} 个签证服务"
