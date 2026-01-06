class HotelPackage < ApplicationRecord
  extend FriendlyId
  friendly_id :title, use: :slugged
  
  has_one_attached :brand_logo
  has_many :hotel_package_orders, dependent: :destroy
  has_many :package_options, dependent: :destroy
  belongs_to :hotel, optional: true
  
  # 套餐类型: standard(标准), vip(会员), limited(限时)
  PACKAGE_TYPES = %w[standard vip limited].freeze
  
  validates :brand_name, presence: true
  validates :title, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :original_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :valid_days, numericality: { greater_than: 0 }
  validates :package_type, inclusion: { in: PACKAGE_TYPES }
  
  scope :featured, -> { where(is_featured: true) }
  scope :by_brand, ->(brand) { where(brand_name: brand) if brand.present? }
  scope :by_region, ->(region) { where(region: region) if region.present? }
  scope :by_city, ->(city) { where(city: city) if city.present? }
  scope :by_type, ->(type) { where(package_type: type) if type.present? && PACKAGE_TYPES.include?(type) }
  scope :refundable, -> { where(refundable: true) }
  scope :instant_booking, -> { where(instant_booking: true) }
  scope :luxury, -> { where(luxury: true) }
  scope :ordered, -> { order(display_order: :asc, sales_count: :desc, created_at: :desc) }
  scope :ordered_by_sales, -> { order(sales_count: :desc, created_at: :desc) }
  
  # 计算折扣
  def discount_rate
    return 0 if original_price.blank? || original_price.zero?
    ((original_price - price) / original_price * 100).round(1)
  end
  
  # 是否有折扣
  def has_discount?
    original_price.present? && original_price > price
  end
  
  # 批量生成酒店套餐
  def self.generate_for_region(region, city, count: 10)
    # 品牌配置
    brands = [
      { name: "华住", logo_url: "https://images.unsplash.com/photo-1566073771259-6a8506099945?w=400" },
      { name: "万豪", logo_url: "https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=400" },
      { name: "希尔顿", logo_url: "https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=400" },
      { name: "洲际", logo_url: "https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=400" },
      { name: "凯悦", logo_url: "https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=400" },
      { name: "香格里拉", logo_url: "https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=400" },
      { name: "温德姆", logo_url: "https://images.unsplash.com/photo-1564501049412-61c2a3083791?w=400" },
      { name: "雅高", logo_url: "https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=400" },
      { name: "锦江", logo_url: "https://images.unsplash.com/photo-1590490360182-c33d57733427?w=400" },
      { name: "首旅如家", logo_url: "https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=400" }
    ]
    
    # 套餐主题模板
    themes = [
      {
        name: "商务出行",
        desc_templates: ["高端商务之选", "商务精选套餐", "商旅优选", "工作日专享"],
        features: ["含早餐", "免费会议室使用", "行政酒廊权益", "免费停车"],
        night_range: [1, 2, 3],
        price_multiplier: 1.2
      },
      {
        name: "家庭亲子",
        desc_templates: ["家庭亲子首选", "亲子度假套餐", "家庭欢乐行", "亲子特惠"],
        features: ["儿童免费", "含双早+双晚餐", "免费游乐设施", "亲子房型"],
        night_range: [2, 3],
        price_multiplier: 1.0
      },
      {
        name: "度假休闲",
        desc_templates: ["度假套餐", "周末度假", "休闲之旅", "放松身心"],
        features: ["含三餐自助", "免费延迟退房", "SPA体验", "景区门票折扣"],
        night_range: [2, 3, 5],
        price_multiplier: 1.1
      },
      {
        name: "奢华体验",
        desc_templates: ["奢华体验套餐", "尊享套餐", "豪华礼遇", "顶级享受"],
        features: ["行政套房", "管家服务", "机场接送", "米其林餐厅体验"],
        night_range: [2, 3],
        price_multiplier: 1.8
      },
      {
        name: "限时特惠",
        desc_templates: ["限时特惠", "早鸟优惠", "秒杀套餐", "特价专享"],
        features: ["限时抢购", "超值优惠", "数量有限", "先到先得"],
        night_range: [2, 5],
        price_multiplier: 0.8
      }
    ]
    
    generated_packages = []
    
    count.times do |i|
      brand = brands.sample
      theme = themes.sample
      
      # 随机选择套餐类型
      package_type = PACKAGE_TYPES.sample
      
      # 随机选择住宿晚数
      night_count = theme[:night_range].sample
      
      # 计算基础价格
      base_price = case night_count
      when 1 then rand(300..600)
      when 2 then rand(600..1200)
      when 3 then rand(900..1800)
      when 5 then rand(1500..2500)
      else rand(600..1200)
      end
      
      # 应用主题价格系数
      price = (base_price * theme[:price_multiplier]).to_i
      original_price = (price * rand(1.2..1.5)).to_i
      
      # 生成标题
      title = "#{brand[:name]}#{theme[:desc_templates].sample} #{city}#{night_count}晚通兑"
      
      # 生成描述
      description = theme[:features].sample(2).join("，")
      
      # 生成条款
      terms = [
        "1. 套餐有效期365天",
        "2. 可在品牌旗下#{city}地区门店使用",
        "3. 需提前#{[1, 2, 3].sample}天预约",
        "4. #{package_type == 'limited' ? '限时优惠，不可退款' : '可退款，需扣除手续费'}",
        "5. 节假日可能需要补差价"
      ].join("\n")
      
      # 创建套餐
      package = create!(
        brand_name: brand[:name],
        title: title,
        description: description,
        price: price,
        original_price: original_price,
        sales_count: rand(50..9999),
        is_featured: rand < 0.3,
        valid_days: 365,
        terms: terms,
        region: region,
        city: city,
        package_type: package_type,
        display_order: i,
        night_count: night_count,
        refundable: package_type != 'limited',
        instant_booking: rand < 0.7,
        luxury: theme[:name] == "奢华体验",
        brand_logo_url: brand[:logo_url]
      )
      
      # 生成套餐选项
      package.generate_options
      
      generated_packages << package
    end
    
    generated_packages
  end
  
  # 生成套餐选项（含/不含早餐等）
  def generate_options
    return if package_options.any?
    
    base_price = price.to_i
    nights = night_count || 2
    
    # 选项1: 标准套餐（不含早餐）
    package_options.create!(
      name: "标准套餐",
      price: base_price,
      original_price: (base_price * 1.3).to_i,
      night_count: nights,
      description: "#{nights}晚住宿，不含早餐",
      display_order: 0
    )
    
    # 选项2: 含早套餐
    package_options.create!(
      name: "含早套餐",
      price: base_price + (nights * 50),
      original_price: ((base_price + (nights * 50)) * 1.3).to_i,
      night_count: nights,
      description: "#{nights}晚住宿，含双人早餐",
      display_order: 1
    )
    
    # 选项3: 豪华套餐（含早+晚餐）
    if nights >= 2
      package_options.create!(
        name: "豪华套餐",
        price: base_price + (nights * 120),
        original_price: ((base_price + (nights * 120)) * 1.3).to_i,
        night_count: nights,
        description: "#{nights}晚住宿，含双人早餐+晚餐",
        display_order: 2
      )
    end
  end
end
