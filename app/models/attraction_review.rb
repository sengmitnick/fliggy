class AttractionReview < ApplicationRecord
  include DataVersionable
  belongs_to :attraction
  belongs_to :user
  
  validates :rating, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 5 }
  validates :comment, presence: true, length: { minimum: 10 }
  
  scope :featured, -> { where(is_featured: true) }
  scope :recent, -> { order(created_at: :desc) }
  scope :helpful, -> { order(helpful_count: :desc) }
  
  after_create :update_attraction_stats
  after_destroy :update_attraction_stats
  
  private
  
  def update_attraction_stats
    attraction.update(
      rating: attraction.attraction_reviews.average(:rating)&.round(1) || 0,
      review_count: attraction.attraction_reviews.count
    )
  end
end
