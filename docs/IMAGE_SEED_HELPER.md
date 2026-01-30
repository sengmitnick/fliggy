# Image Seed Helper - 图片种子管理规则

## 📋 概述

`ImageSeedHelper` 是用于数据包（data packs）中统一管理图片资源的辅助工具。它提供了集中式的图片管理、随机分配和本地缓存功能，避免在多个数据包文件中硬编码图片 URL。

**核心优势：**
- ✅ 集中管理图片资源
- ✅ 避免硬编码 URL
- ✅ 支持批量下载到本地
- ✅ 随机分配不重复
- ✅ 易于维护和扩展

---

## 📂 文件位置

```
app/helpers/image_seed_helper.rb    # 图片辅助工具
public/images/                       # 本地图片存储目录
  ├── attractions/                   # 景点图片
  ├── hotels/                        # 酒店图片
  ├── tours/                         # 旅游产品图片
  ├── tickets/                       # 门票图片
  ├── activities/                    # 活动图片
  ├── packages/                      # 套餐图片
  ├── guides/                        # 导游图片
  └── products/                      # 其他产品图片
```

---

## 🎯 使用规则（MANDATORY）

### 1. **数据包中的图片管理**

**✅ 推荐方式：使用 ImageSeedHelper**

```ruby
# frozen_string_literal: true

# 加载图片辅助工具
require_relative '../../../../../app/helpers/image_seed_helper'

puts "正在加载 hotels_all 数据包..."

hotels_data = []

hotels_data << {
  name: "上海希尔顿酒店",
  address: "上海市静安区华山路250号",
  # ✅ 使用 ImageSeedHelper 随机选择图片
  image_url: ImageSeedHelper.random_image_from_category(:hotels),
  # ... 其他字段
}

Hotel.insert_all(hotels_data)
```

**❌ 不推荐方式：硬编码 Unsplash URL**

```ruby
# ❌ 避免这种写法
hotels_data << {
  name: "上海希尔顿酒店",
  image_url: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800',
  # ...
}
```

---

### 2. **图片分类说明**

目前支持的图片分类（category）：

| 分类 | 说明 | 使用模型 |
|------|------|----------|
| `:attractions` | 景点风景图 | Attraction |
| `:hotels` | 酒店建筑/房间图 | Hotel, HotelPackage |
| `:tours` | 旅游产品图 | TourGroupProduct, TourPackage |
| `:tickets` | 门票/活动图 | Ticket, Activity |
| `:activities` | 体验活动图 | AttractionActivity |
| `:packages` | 套餐产品图 | HotelPackage |
| `:guides` | 导游/服务人员图 | Guide |
| `:products` | 通用产品图 | 其他产品模型 |
| `:cruises` | 游轮/邮轮图 | CruiseSailing, CruiseShip |
| `:flights` | 航班/机场图 | Flight, FlightOffer |
| `:insurances` | 保险产品图 | InsuranceProduct |
| `:visas` | 签证/国家图 | VisaProduct, Country |
| `:cars` | 租车/车辆图 | Car, CarOrder |
| `:shops` | 商家/商店图 | AbroadShop |

---

### 3. **常用方法**

#### `random_image_from_category(category)`
从指定分类中随机选择一张图片

```ruby
# 示例：酒店数据包
hotels_data << {
  name: "北京万豪酒店",
  image_url: ImageSeedHelper.random_image_from_category(:hotels)
}

# 示例：旅游产品数据包
tour_products_data << {
  title: "【精品小团】杭州西湖一日游",
  image_url: ImageSeedHelper.random_image_from_category(:tours)
}
```

#### `random_images_from_category(category, count:)`
随机选择多张图片（不重复）

```ruby
# 示例：景点多图
attractions_data << {
  name: "深圳欢乐谷",
  images: ImageSeedHelper.random_images_from_category(:attractions, count: 3)
}
```

---

## 🔧 工作原理

### 1. **图片 ID 池定义**

在 `image_seed_helper.rb` 中维护 Unsplash 图片 ID 池：

```ruby
UNSPLASH_IMAGE_IDS = {
  hotels: [
    '1566073771259-6a8506099945',  # 酒店外观
    '1542314831-068cd1dbfeeb',      # 酒店大堂
    '1551882547-ff40c63fe5fa',      # 酒店房间
    # ... 更多图片 ID
  ],
  tours: [
    'L19BC2nxBmE',                   # 旅游风景
    'jDwHHjoRPqw',                   # 旅游活动
    # ... 更多图片 ID
  ]
}
```

### 2. **图片存储方式**

**方式 A：使用远程 Unsplash URL（推荐）**
- 直接返回 Unsplash CDN 链接
- 无需本地存储
- 加载速度快

**方式 B：下载到本地（可选）**
- 使用 `download_category_images` 批量下载
- 存储在 `public/images/{category}/` 目录
- 适合需要离线访问的场景

```ruby
# 批量下载酒店图片到本地
ImageSeedHelper.download_category_images(:hotels)
# => 下载到 public/images/hotels/hotel_1.jpg, hotel_2.jpg, ...
```

### 3. **图片路径生成**

```ruby
# 如果本地图片存在，返回本地路径
"/images/hotels/hotel_3.jpg"

# 如果本地图片不存在，返回 Unsplash URL
"https://images.unsplash.com/photo-1566073771259-6a8506099945?w=1200&q=80"
```

---

## 📖 完整示例

### 示例 1：创建酒店数据包

```ruby
# frozen_string_literal: true

# app/validators/support/data_packs/v1/hotels_all.rb

require_relative '../../../../../app/helpers/image_seed_helper'

puts "正在加载 hotels_all 数据包..."

# 清理现有数据
Hotel.where(data_version: 0).destroy_all

timestamp = Time.current
hotels_data = []

# 城市列表
cities = ["深圳", "上海", "北京", "广州", "杭州"]

cities.each do |city|
  5.times do |i|
    hotels_data << {
      name: "#{city}希尔顿酒店#{i+1}号店",
      city: city,
      address: "#{city}市中心#{rand(1..999)}号",
      rating: (4.0 + rand * 1.0).round(1),
      price: rand(400..1200),
      star_level: 5,
      # ✅ 使用 ImageSeedHelper
      image_url: ImageSeedHelper.random_image_from_category(:hotels),
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    }
  end
end

# 批量插入
Hotel.insert_all(hotels_data)

puts "✓ 创建了 #{hotels_data.size} 家酒店"
```

### 示例 2：创建旅游产品数据包

```ruby
# frozen_string_literal: true

# app/validators/support/data_packs/v1/tour_group_products_all.rb

require_relative '../../../../../app/helpers/image_seed_helper'

puts "正在加载 tour_group_products_all 数据包..."

timestamp = Time.current
products_data = []

destinations = ["杭州", "成都", "西安", "三亚"]

destinations.each do |dest|
  3.times do
    products_data << {
      title: "【精品小团】#{dest}深度游 4天3晚",
      destination: dest,
      departure_city: "上海",
      duration: 4,
      price: rand(1888..3088),
      rating: [4.7, 4.8, 4.9, 5.0].sample,
      # ✅ 使用 ImageSeedHelper
      image_url: ImageSeedHelper.random_image_from_category(:tours),
      created_at: timestamp,
      updated_at: timestamp
    }
  end
end

TourGroupProduct.insert_all(products_data)

puts "✓ 创建了 #{products_data.size} 个旅游产品"
```

---

## 🚫 反模式（Anti-Patterns）

### ❌ 反模式 1：硬编码 URL

```ruby
# ❌ 不要这样做
hotels_data << {
  name: "上海希尔顿",
  image_url: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800'
}
```

**问题：**
- URL 分散在多个文件，难以维护
- 无法统一管理图片质量
- 相同 URL 可能重复使用

**✅ 正确做法：**
```ruby
image_url: ImageSeedHelper.random_image_from_category(:hotels)
```

---

### ❌ 反模式 2：重复引用相同图片

```ruby
# ❌ 不要这样做
hotels_data << { name: "酒店A", image_url: 'photo-123.jpg' }
hotels_data << { name: "酒店B", image_url: 'photo-123.jpg' }
hotels_data << { name: "酒店C", image_url: 'photo-123.jpg' }
```

**问题：**
- 多个记录使用相同图片，缺乏多样性

**✅ 正确做法：**
```ruby
# random_image_from_category 会自动随机选择不同的图片
hotels_data << { name: "酒店A", image_url: ImageSeedHelper.random_image_from_category(:hotels) }
hotels_data << { name: "酒店B", image_url: ImageSeedHelper.random_image_from_category(:hotels) }
hotels_data << { name: "酒店C", image_url: ImageSeedHelper.random_image_from_category(:hotels) }
```

---

### ❌ 反模式 3：混用本地路径和远程 URL

```ruby
# ❌ 不要这样做
hotels_data << { name: "酒店A", image_url: '/images/hotels/hotel_1.jpg' }
hotels_data << { name: "酒店B", image_url: 'https://images.unsplash.com/photo-xxx' }
hotels_data << { name: "酒店C", image_url: ImageSeedHelper.random_image_from_category(:hotels) }
```

**问题：**
- 图片来源不一致
- 难以统一管理

**✅ 正确做法：**
```ruby
# 统一使用 ImageSeedHelper
hotels_data.each do |hotel|
  hotel[:image_url] = ImageSeedHelper.random_image_from_category(:hotels)
end
```

---

## 🔄 迁移旧代码

如果现有数据包使用硬编码 URL，可按以下步骤迁移：

### 步骤 1：添加 require

```ruby
# 在文件顶部添加
require_relative '../../../../../app/helpers/image_seed_helper'
```

### 步骤 2：替换 image_url 赋值

```ruby
# 旧代码
hotels_data << {
  name: "上海希尔顿",
  image_url: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800',
  # ...
}

# 新代码
hotels_data << {
  name: "上海希尔顿",
  image_url: ImageSeedHelper.random_image_from_category(:hotels),
  # ...
}
```

### 步骤 3：测试数据包加载

```bash
rake validator:reset_baseline
```

---

## 🆕 扩展新分类

如需添加新的图片分类：

### 步骤 1：编辑 image_seed_helper.rb

```ruby
UNSPLASH_IMAGE_IDS = {
  # ... 现有分类
  cruises: [  # 新增游轮分类
    '1548574505-5e239809ee19',
    '1563298723-dcfebaa392e3',
    '1520250497591-112f2f40a3f4'
  ]
}
```

### 步骤 2：在数据包中使用

```ruby
cruise_ships_data << {
  name: "海洋光谱号",
  image_url: ImageSeedHelper.random_image_from_category(:cruises)
}
```

---

## 🛠️ 维护任务

### 下载所有图片到本地

```bash
# 进入 Rails 控制台
rails console

# 下载指定分类
ImageSeedHelper.download_category_images(:hotels)
ImageSeedHelper.download_category_images(:tours)

# 或批量下载所有分类
[:attractions, :hotels, :tours, :tickets, :activities, :packages, :guides, :products].each do |category|
  ImageSeedHelper.download_category_images(category)
end
```

### 清理本地图片

```bash
rails console

# 清理指定分类
ImageSeedHelper.clean_category_images(:hotels)

# 清理所有图片
ImageSeedHelper.clean_all_images
```

---

## ⚠️ 注意事项

1. **Unsplash API 限制**
   - 如果频繁访问可能触发 rate limit
   - 建议将图片下载到本地使用

2. **图片版权**
   - Unsplash 图片遵循 Unsplash License
   - 可免费用于商业和非商业用途
   - 无需署名（但建议署名）

3. **性能考虑**
   - 远程图片加载速度取决于网络
   - 大量图片场景建议下载到本地
   - 本地图片访问速度更快

4. **数据包兼容性**
   - 旧数据包保持现状，逐步迁移
   - 新数据包强制使用 ImageSeedHelper
   - 特殊需求（如品牌 Logo）可使用本地路径

---

## 📚 相关文档

- **Data Packs 文档**: 查看 `.clackyrules` 文件中的 "Data Packs - Test/Validation Data Management" 部分
- **Validator 文档**: `docs/VALIDATOR_GENERATOR.md`
- **图片管理工具**: `app/helpers/image_seed_helper.rb`

---

## ✅ 检查清单

在创建或修改数据包时，确保：

- [ ] 已添加 `require_relative '../../../../../app/helpers/image_seed_helper'`
- [ ] 所有 `image_url` 字段使用 `ImageSeedHelper.random_image_from_category(:category)`
- [ ] 选择了正确的图片分类（:hotels, :tours, :attractions 等）
- [ ] 没有硬编码 Unsplash URL
- [ ] 运行 `rake validator:reset_baseline` 测试数据加载
- [ ] 运行 `rake validator:simulate` 验证数据完整性

---

**最后更新时间**: 2024年（当前会话）
**维护者**: AI Coding Assistant
