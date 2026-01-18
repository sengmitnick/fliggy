class TourReview < ApplicationRecord
  include DataVersionable
  belongs_to :tour_group_product
  belongs_to :user
  has_many_attached :images

  validates :rating, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 5 }
  validates :comment, presence: true

  scope :featured, -> { where(is_featured: true) }
  scope :recent, -> { order(created_at: :desc) }
  scope :helpful, -> { order(helpful_count: :desc) }
  scope :top_rated, -> { where("rating >= 4.5").order(rating: :desc) }

  def average_sub_rating
    (guide_attitude + meal_quality + itinerary_arrangement + travel_transportation) / 4.0
  end

  def rating_text
    return "超棒" if rating >= 4.8
    return "很棒" if rating >= 4.0
    return "满意" if rating >= 3.0
    "一般"
  end
end
