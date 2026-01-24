class Attraction < ApplicationRecord
  include DataVersionable
  extend FriendlyId
  friendly_id :name, use: :slugged
  
  # Associations from both branches
  has_many :route_attractions, dependent: :destroy
  has_many :charter_routes, through: :route_attractions
  has_many :tickets, dependent: :destroy
  has_many :attraction_activities, dependent: :destroy
  has_many :tour_group_products, dependent: :nullify
  has_many :attraction_reviews, dependent: :destroy
  has_one_attached :cover_image
  has_many_attached :gallery_images
  
  # Validations
  validates :name, presence: true
  validates :city, presence: true
  validates :rating, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 5 }, allow_nil: true
  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }, allow_nil: true
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }, allow_nil: true
  
  # Scopes
  scope :by_city, ->(city) { where("city LIKE ?", "%#{city}%") if city.present? }
  scope :by_province, ->(province) { where(province: province) if province.present? }
  scope :featured, -> { where("rating >= ?", 4.5).order(review_count: :desc) }
  scope :with_coordinates, -> { where.not(latitude: nil, longitude: nil) }
  
  # 附近酒店（基于城市匹配，因为没有精确经纬度）
  def nearby_hotels(limit = 10)
    return Hotel.none if city.blank?
    
    Hotel.by_city(city).limit(limit)
  end
  
  # 关联的跟团游
  def related_tours(limit = 5)
    tour_group_products.limit(limit)
  end
  
  # 平均评分
  def average_rating
    attraction_reviews.average(:rating)&.round(1) || rating || 0
  end
  
  # 评价数
  def reviews_count
    attraction_reviews.count
  end
end
