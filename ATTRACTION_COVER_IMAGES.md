# 景点封面图片添加

## 问题描述
景点详情页面（如 `/attractions/shenzhen-happy-harbor`）缺少封面图片，显示的是灰色占位符和表情符号。

## 解决方案
为所有景点添加了封面图片，使用 Unsplash 提供的高质量旅游景点图片。

## 技术实现

### 1. 检查现有状态
```ruby
rails runner "
  attraction = Attraction.find_by(slug: 'shenzhen-happy-harbor')
  puts 'Cover attached: ' + attraction.cover_image.attached?.to_s
"
# 结果: false（没有封面图片）
```

### 2. 为所有景点添加封面图片
```ruby
require 'open-uri'

# 获取所有没有封面图片的景点
attractions = Attraction.where.missing(:cover_image_attachment)

attractions.each do |attraction|
  # 使用 Unsplash 高质量图片
  image_url = 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1200'
  
  # 下载并附加图片
  io = URI.open(image_url)
  attraction.cover_image.attach(
    io: io, 
    filename: 'cover.jpg', 
    content_type: 'image/jpeg'
  )
end
```

### 3. 视图逻辑（已存在）
**文件**: `app/views/attractions/show.html.erb`

```erb
<!-- Image Gallery -->
<div class="relative bg-surface">
  <% if @attraction.cover_image.attached? %>
    <%= image_tag @attraction.cover_image, class: "w-full h-80 object-cover" %>
  <% else %>
    <div class="w-full h-80 bg-gray-200 flex items-center justify-center">
      <span class="text-6xl">🎫</span>
    </div>
  <% end %>
  
  <% if @attraction.gallery_images.attached? && @attraction.gallery_images.count > 0 %>
    <div class="absolute bottom-4 right-4 px-3 py-1 bg-surface-dark/80 backdrop-blur-sm rounded-full text-sm text-white">
      1/<%= @attraction.gallery_images.count + 1 %>
    </div>
  <% end %>
</div>
```

## 添加的景点封面

| 景点名称 | Slug | 状态 |
|---------|------|------|
| 深圳欢乐港湾 | shenzhen-happy-harbor | ✅ 已添加 |
| 杭州宋城 | hangzhou-songcheng | ✅ 已添加 |
| 成都欢乐谷 | chengdu-happy-valley | ✅ 已添加 |
| 上海迪士尼乐园 | shanghai-disneyland | ✅ 已添加 |
| 北京环球影城 | beijing-universal-studios | ✅ 已添加 |
| 广州长隆欢乐世界 | guangzhou-chimelong | ✅ 已添加 |

## 图片来源
- **平台**: Unsplash (https://unsplash.com)
- **类型**: 高质量旅游景点照片
- **尺寸**: 1200px 宽（响应式）
- **格式**: JPEG

## 验证结果
访问 `/attractions/shenzhen-happy-harbor` 确认：
- ✅ 封面图片正常显示
- ✅ 图片尺寸适配（w-full h-80）
- ✅ 图片居中覆盖（object-cover）
- ✅ 不再显示灰色占位符

## 后续优化建议
1. 为每个景点选择更具代表性的图片
2. 添加画廊图片（gallery_images）展示更多景点照片
3. 考虑添加图片懒加载以提升性能
4. 为不同类型的景点使用对应主题的图片
