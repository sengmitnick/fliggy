class TourGroupProduct < ApplicationRecord
  belongs_to :travel_agency
  has_many :tour_packages, dependent: :destroy
  has_many :tour_itinerary_days, -> { order(day_number: :asc) }, dependent: :destroy
  has_many :tour_reviews, dependent: :destroy
  has_one_attached :main_image
  has_many_attached :gallery_images

  serialize :highlights, coder: JSON
  serialize :tags, coder: JSON

  validates :title, presence: true
  validates :tour_category, inclusion: { in: %w[comprehensive group_tour private_group free_travel outbound_essentials] }
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
end
