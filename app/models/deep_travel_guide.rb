class DeepTravelGuide < ApplicationRecord
  # ActiveStorage attachments
  has_one_attached :avatar
  has_one_attached :video
  
  # Associations
  has_many :deep_travel_products, dependent: :destroy
  
  # Validations
  validates :name, presence: true
  validates :title, presence: true
  validates :follower_count, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :experience_years, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :served_count, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :rating, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 5 }, allow_nil: true
  
  # Scopes
  scope :featured, -> { where(featured: true) }
  scope :by_rank, -> { order(rank: :asc) }
  
  # Helper methods
  def avatar_url
    attachment_url(avatar)
  end
  
  def video_url
    attachment_url(video)
  end
end
