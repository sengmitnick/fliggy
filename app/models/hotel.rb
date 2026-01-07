class Hotel < ApplicationRecord
  has_one_attached :image
  has_many :hotel_rooms, dependent: :destroy
  has_many :rooms, dependent: :destroy
  has_one :hotel_policy, dependent: :destroy
  has_many :hotel_reviews, dependent: :destroy
  has_many :hotel_facilities, dependent: :destroy
  has_many :hotel_bookings, dependent: :destroy
  has_many :hotel_packages, dependent: :nullify

  serialize :features, coder: JSON

  # 住宿类型: hotel(酒店), homestay(民宿)
  HOTEL_TYPES = %w[hotel homestay].freeze

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
  scope :by_price_range, ->(min, max) { where(price: min..max) if min.present? && max.present? }
  scope :by_star_level, ->(level) { where(star_level: level) if level.present? }
  scope :by_type, ->(type) { where(hotel_type: type) if type.present? && HOTEL_TYPES.include?(type) }
  scope :domestic, -> { where(is_domestic: true) }
  scope :international, -> { where(is_domestic: false) }
  scope :ordered, -> { order(display_order: :asc, created_at: :desc) }
  
  # 查询有钟点房的住宿场所
  scope :with_hourly_rooms, -> { 
    joins(:hotel_rooms).where(hotel_rooms: { room_category: 'hourly' }).distinct 
  }
  
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
