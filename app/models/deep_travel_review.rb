class DeepTravelReview < ApplicationRecord
  include DataVersionable
  
  belongs_to :deep_travel_guide
  belongs_to :user
  
  validates :rating, presence: true, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }
  validates :content, presence: true, length: { minimum: 10, maximum: 500 }
  validates :visit_date, presence: true
  
  scope :recent, -> { order(created_at: :desc) }
  scope :helpful, -> { order(helpful_count: :desc) }
end
