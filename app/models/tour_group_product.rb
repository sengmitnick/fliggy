# encoding: utf-8
class TourGroupProduct < ApplicationRecord
  include DataVersionable
  belongs_to :travel_agency
  has_many :tour_packages, dependent: :destroy
  has_many :tour_itinerary_days, -> { order(day_number: :asc) }, dependent: :destroy
  has_many :tour_reviews, dependent: :destroy
  has_one_attached :main_image
  has_many_attached :gallery_images

  serialize :highlights, coder: JSON
  serialize :tags, coder: JSON

  validates :title, presence: true
  validates :tour_category, inclusion: { in: %w[comprehensive group_tour private_group free_travel outbound_essentials ticket] }
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :duration, numericality: { greater_than: 0 }

  scope :by_category, ->(category) { where(tour_category: category) }
  scope :by_destination, ->(destination) { where("destination LIKE ?", "%#{destination}%") }
  scope :by_departure_city, ->(city) { where(departure_city: city) }
  scope :featured, -> { where(is_featured: true) }
  scope :by_display_order, -> { order(display_order: :asc) }
  scope :popular, -> { order(sales_count: :desc) }
  scope :top_rated, -> { where("rating > 0").order(rating: :desc) }

  # 辅助方法
  def format_price
    "¥#{price.to_i}"
  end

  def format_sales
    return "" if sales_count == 0
    return "已售#{sales_count}" if sales_count < 10000
    "已售#{(sales_count / 10000.0).round(1)}万+"
  end

  def average_rating
    return rating if tour_reviews.empty?
    tour_reviews.average(:rating)&.round(1) || rating
  end

  def review_count
    tour_reviews.count
  end

  def featured_reviews
    tour_reviews.where(is_featured: true).limit(3)
  end

  # 批量生成旅游产品
  def self.generate_for_destination(destination, departure_city, start_date, end_date, count_per_day: 5)
    # 旅游类型配置
    tour_types = [
      { tour_category: 'group_tour', badge: '跟团游', travel_type: '跟团游', weight: 40 },
      { tour_category: 'private_group', badge: '私家团', travel_type: '独立成团', weight: 30 },
      { tour_category: 'free_travel', badge: '自由行', travel_type: '自由出行', weight: 20 },
      { tour_category: 'outbound_essentials', badge: '出境必备', travel_type: '自由出行', weight: 10 }
    ]
    
    # 旅行社池
    agencies = TravelAgency.all.to_a
    return [] if agencies.empty?
    
    # 目的地主题模板（增加与筛选标签对应的特色）
    # 筛选标签：不用早起、往返直飞、全额退、无自费、纯玩无购物、小团出行、含门票、上门接送
    themes = [
      { 
        name: '古镇漫游', 
        highlights: ['古镇风情', '人文历史', '美食体验'], 
        tags: ['历史文化', '美食'],
        special_tags: ['不用早起', '纯玩无购物', '含门票'].sample(rand(1..2)),
        images: [
          'https://images.unsplash.com/photo-1548919973-5cef591cdbc9?w=800',
          'https://images.unsplash.com/photo-1508804185872-d7badad00f7d?w=800',
          'https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=800'
        ]
      },
      { 
        name: '山水之旅', 
        highlights: ['自然风光', '登山涉水', '生态体验'], 
        tags: ['自然风光', '户外探险'],
        special_tags: ['往返直飞', '小团出行', '含门票'].sample(rand(1..2)),
        images: [
          'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800',
          'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=800',
          'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800'
        ]
      },
      { 
        name: '都市休闲', 
        highlights: ['城市观光', '购物天堂', '美食打卡'], 
        tags: ['城市漫步', '美食'],
        special_tags: ['不用早起', '上门接送', '无自费'].sample(rand(1..2)),
        images: [
          'https://images.unsplash.com/photo-1514565131-fce0801e5785?w=800',
          'https://images.unsplash.com/photo-1480714378408-67cf0d13bc1b?w=800',
          'https://images.unsplash.com/photo-1449824913935-59a10b8d2000?w=800'
        ]
      },
      { 
        name: '海岛度假', 
        highlights: ['海滨度假', '水上项目', '阳光沙滩'], 
        tags: ['海滨度假', '亲子游'],
        special_tags: ['往返直飞', '全额退', '上门接送'].sample(rand(1..2)),
        images: [
          'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=800',
          'https://images.unsplash.com/photo-1473496169904-658ba7c44d8a?w=800',
          'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800'
        ]
      },
      { 
        name: '文化探索', 
        highlights: ['博物馆参观', '文化遗产', '艺术体验'], 
        tags: ['文化艺术', '深度体验'],
        special_tags: ['小团出行', '纯玩无购物', '含门票'].sample(rand(1..2)),
        images: [
          'https://images.unsplash.com/photo-1555881400-74d7acaacd8b?w=800',
          'https://images.unsplash.com/photo-1533929736458-ca588d08c8be?w=800',
          'https://images.unsplash.com/photo-1520760693108-c8bb8944290a?w=800'
        ]
      },
      { 
        name: '亲子乐园', 
        highlights: ['家庭娱乐', '儿童友好', '寓教于乐'], 
        tags: ['亲子游', '家庭出游'],
        special_tags: ['不用早起', '上门接送', '无自费'].sample(rand(1..2)),
        images: [
          'https://images.unsplash.com/photo-1503454537195-1dcabb73ffb9?w=800',
          'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800',
          'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=800'
        ]
      },
      { 
        name: '美食之旅', 
        highlights: ['地道美食', '米其林餐厅', '特色小吃'], 
        tags: ['美食', '深度体验'],
        special_tags: ['纯玩无购物', '小团出行', '不用早起'].sample(rand(1..2)),
        images: [
          'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800',
          'https://images.unsplash.com/photo-1476224203421-9ac39bcb3327?w=800',
          'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=800'
        ]
      },
      { 
        name: '豪华精品', 
        highlights: ['五星酒店', '管家服务', '尊享体验'], 
        tags: ['奢华游', '品质保障'],
        special_tags: ['往返直飞', '全额退', '上门接送'].sample(rand(2..3)),
        images: [
          'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800',
          'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800',
          'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=800'
        ]
      }
    ]
    
    generated_products = []
    
    (start_date..end_date).each do |date|
      count_per_day.times do
        # 选择旅游类型（按权重）
        rand_value = rand(100)
        cumulative = 0
        selected_type = tour_types.find do |type|
          cumulative += type[:weight]
          rand_value < cumulative
        end || tour_types.first
        
        # 选择主题
        theme = themes.sample
        
        # 生成天数（1-8天，确保覆盖所有筛选选项）
        duration = [1, 2, 3, 4, 5, 6, 7, 8].sample
        
        # 生成价格（根据天数）
        base_price = case duration
        when 1 then rand(500..1000)
        when 2 then rand(800..1500)
        when 3 then rand(1500..2500)
        when 4 then rand(2000..3500)
        when 5 then rand(2800..4500)
        when 6 then rand(3500..5500)
        when 7 then rand(4000..6500)
        when 8 then rand(5000..8000)
        end
        
        original_price = (base_price * rand(1.1..1.3)).to_i
        
        # 生成评分
        rating = [4.5, 4.6, 4.7, 4.8, 4.9, 5.0].sample
        rating_desc = "#{rand(100..500)}条评价"
        
        # 生成销量
        sales_count = rand(50..500)
        
        # 生成标题（根据天数调整）
        nights = duration > 1 ? duration - 1 : 1
        title = "#{destination}#{theme[:name]} #{duration}天#{nights}晚 含#{['2晚酒店', '餐食', '门票', '导游'].sample}"
        
        # 生成副标题（包含特色标签）
        subtitles = [
          "精选酒店 贴心服务",
          "品质保障 放心出游",
          "深度体验 精彩行程",
          "小团慢游 舒适自由",
          "全程陆同 无购物安排",
          "豪华五星 管家服务",
          "亲子首选 儿童友好",
          "美食之旅 饕餮盛宴"
        ]
        
        # 合并基础标签和特色标签
        all_tags = theme[:tags] + theme[:special_tags]
        
        product = create!(
          title: title,
          subtitle: subtitles.sample,
          tour_category: selected_type[:tour_category],
          travel_type: selected_type[:travel_type],
          destination: destination,
          duration: duration,
          departure_city: departure_city,
          price: base_price,
          original_price: original_price,
          rating: rating,
          rating_desc: rating_desc,
          highlights: theme[:highlights] + theme[:special_tags],
          tags: all_tags,
          sales_count: sales_count,
          badge: selected_type[:badge],
          departure_label: date.strftime('%m月%d日'),
          image_url: theme[:images].sample,
          is_featured: rand < 0.2, # 20%概率为推荐
          display_order: rand(1..100),
          travel_agency: agencies.sample
        )
        
        # 生成套餐
        product.generate_packages
        
        # 生成行程
        product.generate_itinerary
        
        generated_products << product
      end
    end
    
    generated_products
  end
  
  # 生成套餐
  def generate_packages
    return if tour_packages.any?
    
    base_price = price.to_i
    
    # 经济型
    tour_packages.create!(
      name: '经济型',
      price: base_price,
      child_price: (base_price * 0.7).to_i,
      description: '三星酒店 经济实惠',
      is_featured: true,
      display_order: 0
    )
    
    # 舒适型
    tour_packages.create!(
      name: '舒适型',
      price: base_price + rand(300..600),
      child_price: ((base_price + 400) * 0.7).to_i,
      description: '四星酒店 品质保障',
      is_featured: false,
      display_order: 1
    )
    
    # 豪华型
    tour_packages.create!(
      name: '豪华型',
      price: base_price + rand(800..1200),
      child_price: ((base_price + 1000) * 0.7).to_i,
      description: '五星酒店 尊享体验',
      is_featured: false,
      display_order: 2
    )
  end
  
  # 生成行程
  def generate_itinerary
    return if tour_itinerary_days.any?
    
    duration.times do |i|
      day_number = i + 1
      
      if day_number == 1
        # 第一天
        tour_itinerary_days.create!(
          day_number: day_number,
          title: "出发日 - 抵达#{destination}",
          attractions: ["从#{departure_city}出发", "#{destination}机场/车站", '酒店办理入住'],
          assembly_point: "#{departure_city}机场/车站",
          transportation: '飞机/高铁',
          service_info: '包含接站服务，专人引导入住',
          duration_minutes: 480
        )
      elsif day_number == duration
        # 最后一天
        tour_itinerary_days.create!(
          day_number: day_number,
          title: "返程日 - 返回#{departure_city}",
          attractions: ['酒店退房', "送机/送站服务", "返回#{departure_city}"],
          disassembly_point: "#{destination}机场/车站",
          transportation: '飞机/高铁',
          service_info: '包含送站服务，感谢您的选择',
          duration_minutes: 360
        )
      else
        # 中间天
        tour_itinerary_days.create!(
          day_number: day_number,
          title: "#{destination}精华景点游览",
          attractions: ["#{destination}经典景点#{day_number - 1}", "特色景区#{day_number - 1}", '自由活动时间'],
          transportation: '旅游大巴',
          service_info: '全天游览，包含景点门票和导游服务',
          duration_minutes: 540
        )
      end
    end
  end
end
