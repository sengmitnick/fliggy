class Hotel < ApplicationRecord
  include DataVersionable
  # 图片字段 (使用本地路径或外部 URL)
  # image_url: 酒店主图
  has_many :hotel_rooms, dependent: :destroy
  has_many :rooms, dependent: :destroy
  has_one :hotel_policy, dependent: :destroy
  has_many :hotel_reviews, dependent: :destroy
  has_many :hotel_facilities, dependent: :destroy
  has_many :hotel_bookings, dependent: :destroy
  has_many :hotel_packages, dependent: :nullify
  has_many :hotel_highlights, -> { order(:display_order) }, dependent: :destroy
  has_many :hotel_nearby_places, -> { order(:display_order) }, dependent: :destroy

  serialize :features, coder: JSON

  # 住宿类型: hotel(酒店), homestay(民宿)
  HOTEL_TYPES = %w[hotel homestay].freeze
  
  # 城市地标配置 - 用于快速筛选
  CITY_LANDMARKS = {
    '深圳' => ['亲子', '罗湖', '南山', '宝安机场', '科技园'],
    '深圳市' => ['亲子', '罗湖', '南山', '宝安机场', '科技园'],
    '北京' => ['亲子', 'CBD', '机场', '金融街', '科技园'],
    '北京市' => ['亲子', 'CBD', '机场', '金融街', '科技园'],
    '上海' => ['亲子', '机场', 'CBD', '会展中心', '科技园'],
    '上海市' => ['亲子', '机场', 'CBD', '会展中心', '科技园'],
    '广州' => ['亲子', '会展中心', 'CBD', '机场', '科技园'],
    '广州市' => ['亲子', '会展中心', 'CBD', '机场', '科技园'],
    '杭州' => ['亲子', '西湖', '灵隐寺', '火车站', '机场'],
    '杭州市' => ['亲子', '西湖', '灵隐寺', '火车站', '机场'],
    '成都' => ['亲子', '宽窄巷子', '科技园', '会展中心', '机场'],
    '成都市' => ['亲子', '宽窄巷子', '科技园', '会展中心', '机场'],
    '西安' => ['亲子', 'CBD', '金融街', '会展中心', '新城区'],
    '西安市' => ['亲子', 'CBD', '金融街', '会展中心', '新城区'],
    '重庆' => ['亲子', '新城区', '机场', '中心商务区', '科技园'],
    '重庆市' => ['亲子', '新城区', '机场', '中心商务区', '科技园'],
    '南京' => ['亲子', '新城区', '金融街', '会展中心', '机场'],
    '南京市' => ['亲子', '新城区', '金融街', '会展中心', '机场'],
    '武汉' => ['亲子', '滨海路', '新城区', '老城区', '会展中心'],
    '武汉市' => ['亲子', '滨海路', '新城区', '老城区', '会展中心'],
    '苏州' => ['亲子', '拙政园', '苏州站', '观前街', '金鸡湖'],
    '苏州市' => ['亲子', '拙政园', '苏州站', '观前街', '金鸡湖']
  }.freeze
  
  # 获取城市的地标列表
  def self.landmarks_for_city(city)
    return [] if city.blank?
    
    # 尝试直接匹配
    landmarks = CITY_LANDMARKS[city]
    return landmarks if landmarks.present?
    
    # 尝试移除"市"后匹配
    base_city = city.gsub(/市.*$/, '')
    landmarks = CITY_LANDMARKS[base_city]
    return landmarks if landmarks.present?
    
    # 尝试添加"市"后匹配
    landmarks = CITY_LANDMARKS["#{base_city}市"]
    return landmarks if landmarks.present?
    
    # 默认返回深圳的地标
    CITY_LANDMARKS['深圳'] || []
  end

  validates :name, presence: true
  validates :city, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :rating, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 5 }, allow_nil: true
  validates :star_level, inclusion: { in: 1..5 }, allow_nil: true
  validates :hotel_type, inclusion: { in: HOTEL_TYPES }, allow_nil: true

  scope :featured, -> { where(is_featured: true) }
  scope :by_city, ->(city) { 
    return all if city.blank?
    # 智能城市匹配：支持区级搜索匹配市级数据
    # 同时支持 "深圳" 和 "深圳市" 相互匹配
    # 例如："深圳市南山区" 可以匹配 "深圳市" 或 "深圳"
    
    # 移除"市"字符以获取基础城市名
    base_city_name = city.gsub(/市.*$/, '')
    
    # 构建匹配条件：支持多种格式
    # 1. 精确匹配
    # 2. 基础城市名匹配（如 "深圳" 匹配 "深圳市"）
    # 3. 基础城市名 + 市匹配（如 "深圳市" 匹配 "深圳"）
    where(
      "city = :exact OR city = :base OR city = :base_with_city",
      exact: city,
      base: base_city_name,
      base_with_city: "#{base_city_name}市"
    )
  }
  scope :by_region, ->(region) { where(region: region) if region.present? }
  scope :by_price_range, ->(min, max) {
    if min.present? && max.present? && min.to_i >= 0 && max.to_i > 0
      where(price: min.to_i..max.to_i)
    elsif min.present? && min.to_i >= 0
      where('price >= ?', min.to_i)
    elsif max.present? && max.to_i > 0
      where('price <= ?', max.to_i)
    end
  }
  scope :by_star_level, ->(level) { where(star_level: level) if level.present? }
  scope :by_type, ->(type) { where(hotel_type: type) if type.present? && HOTEL_TYPES.include?(type) }
  scope :domestic, -> { where(is_domestic: true) }
  scope :international, -> { where(is_domestic: false) }
  scope :ordered, -> { order(display_order: :asc, created_at: :desc) }
  
  # 查询有钟点房的住宿场所
  scope :with_hourly_rooms, -> { 
    joins(:hotel_rooms).where(hotel_rooms: { room_category: 'hourly' }).distinct 
  }
  
  # 查询有月租房的住宿场所
  scope :with_monthly_rooms, -> { 
    joins(:hotel_rooms).where(hotel_rooms: { room_category: 'monthly' }).distinct 
  }
  
  # 获取最低过夜房价（用于整晚搜索）
  def min_overnight_price
    hotel_rooms.where(room_category: 'overnight').minimum(:price) || price
  end
  
  # 获取最低钟点房价（用于钟点房搜索）
  def min_hourly_price
    hotel_rooms.where(room_category: 'hourly').minimum(:price) || price
  end
  
  # 根据房型分类获取显示价格
  # 默认为整晚房价（不包含钟点房）
  def display_price(room_category = nil)
    case room_category
    when 'hourly'
      min_hourly_price
    else
      # 默认显示整晚房价，过滤掉钟点房
      min_overnight_price
    end
  end
  
  # 酒店评分计算
  def average_rating
    hotel_reviews.average(:rating) || rating || 0
  end
  
  # 评论数量
  def reviews_count
    hotel_reviews.count
  end
  
  # 获取酒店距离信息
  def distance_info
    "距酒店驾车#{rand(1..10)}.#{rand(1..9)}公里·#{rand(10..60)}分钟"
  end
end
