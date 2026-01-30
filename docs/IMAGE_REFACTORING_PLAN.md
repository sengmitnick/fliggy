# 图片管理重构方案

## 背景

当前项目使用 ActiveStorage 存储图片，但这种方式在数据包 (data_packs/v1/) 加载时存在问题：
1. 需要使用 `URI.open` 下载远程图片，速度慢
2. 数据包无法使用 `insert_all` 批量操作
3. Unsplash 图片可能失效

## 新方案：本地图片 + image_url 字段

### 1. 目录结构

```
public/images/
├── attractions/       # 景点图片 (3-5张)
├── hotels/           # 酒店图片 (3-5张)
├── tickets/          # 门票图片 (3张)
├── activities/       # 景点内项目图片 (3张)
├── tours/            # 跟团游图片 (5-8张)
├── packages/         # 套餐图片 (3张)
├── guides/           # 深度游导游头像 (3张)
└── products/         # 其他产品图片 (3张)
```

### 2. 图片命名规范

- 景点: `attraction_1.jpg`, `attraction_2.jpg`, `attraction_3.jpg`
- 酒店: `hotel_1.jpg`, `hotel_2.jpg`, `hotel_3.jpg`
- 门票: `ticket_1.jpg`, `ticket_2.jpg`, `ticket_3.jpg`
- 跟团游: `tour_1.jpg` ~ `tour_8.jpg`

### 3. 模型迁移计划

#### 需要迁移的模型

| 模型 | 当前 ActiveStorage 字段 | 新字段 | 说明 |
|-----|----------------------|-------|------|
| Attraction | cover_image, gallery_images | cover_image_url, gallery_image_urls (JSON) | 景点封面和相册 |
| Hotel | image | image_url | 酒店主图 |
| Ticket | image | image_url | 门票图片 |
| AttractionActivity | image | image_url | 景点内项目图片 |
| TourGroupProduct | main_image, gallery_images | main_image_url, gallery_image_urls (JSON) | 跟团游主图和相册 |
| HotelPackage | brand_logo | brand_logo_url | 套餐品牌Logo |
| DeepTravelGuide | avatar, video | avatar_url, video_url | 导游头像和视频 |
| MembershipProduct | image | image_url | 会员产品图片 |
| DeepTravelProduct | images | image_urls (JSON) | 深度游产品图片 |
| TourReview | images | image_urls (JSON) | 评论图片 |

### 4. 辅助工具设计

创建 `app/helpers/image_helper_module.rb`:

```ruby
module ImageHelperModule
  # 从图片池随机选择一张图片
  def random_image_from_category(category)
    "/images/#{category}/#{category}_#{rand(1..3)}.jpg"
  end
  
  # 从 Unsplash 下载图片到本地
  def download_seed_images(category, count: 3)
    # 下载逻辑
  end
  
  # 获取图片的完整 URL
  def image_url_for(path)
    return nil if path.blank?
    path.start_with?('http') ? path : path
  end
end
```

### 5. 数据包使用方式

```ruby
# 数据包中直接使用本地图片路径
attractions_data = [
  {
    name: "深圳欢乐港湾",
    cover_image_url: "/images/attractions/attraction_1.jpg",
    gallery_image_urls: [
      "/images/attractions/attraction_2.jpg",
      "/images/attractions/attraction_3.jpg"
    ],
    # ... 其他字段
  }
]

Attraction.insert_all(attractions_data)
```

### 6. 种子图片下载任务

创建 `lib/tasks/seed_images.rake`:

```bash
rake images:seed              # 下载所有种子图片
rake images:seed[attractions] # 只下载景点图片
rake images:clean             # 清理所有下载的图片
```

### 7. 迁移步骤

1. ✅ 分析现有 ActiveStorage 使用情况
2. ⏳ 设计新方案（当前）
3. 创建 ImageHelper 辅助工具
4. 添加新字段的数据库迁移
5. 更新所有模型，移除 ActiveStorage 关联
6. 更新所有视图文件
7. 更新所有数据包文件
8. 创建种子图片下载任务
9. 清理 ActiveStorage 相关表和配置
10. 运行测试

### 8. 优势

- ✅ 数据包加载快速（直接 insert_all）
- ✅ 图片稳定可控（本地存储）
- ✅ 开发简单（无需处理 ActiveStorage 复杂性）
- ✅ 种子图片少（每类 3-8 张）
- ✅ 支持外部 URL（仍可使用 Unsplash）

### 9. 注意事项

- 保留 `image_url` 字段支持外部 URL（Unsplash等）
- `gallery_image_urls` 使用 JSON 数组存储多张图片
- 视图中需要处理 `image_url` 为空的情况
- 管理后台上传功能需要调整（上传到 public/uploads/）
