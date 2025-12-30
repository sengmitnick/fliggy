class Hotel < ApplicationRecord
  has_one_attached :image
  has_many :hotel_rooms, dependent: :destroy
  has_many :rooms, dependent: :destroy
  has_one :hotel_policy, dependent: :destroy
  has_many :hotel_reviews, dependent: :destroy
  has_many :hotel_facilities, dependent: :destroy
  has_many :hotel_bookings, dependent: :destroy

  serialize :features, coder: JSON

  validates :name, presence: true
  validates :city, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :rating, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 5 }, allow_nil: true
  validates :star_level, inclusion: { in: 1..5 }, allow_nil: true

  scope :featured, -> { where(is_featured: true) }
  scope :by_city, ->(city) { where(city: city) if city.present? }
  scope :by_price_range, ->(min, max) { where(price: min..max) if min.present? && max.present? }
  scope :by_star_level, ->(level) { where(star_level: level) if level.present? }
  scope :ordered, -> { order(display_order: :asc, created_at: :desc) }
  
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
