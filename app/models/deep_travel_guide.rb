class DeepTravelGuide < ApplicationRecord
  include DataVersionable
  # 图片/视频字段 (使用本地路径或外部 URL)
  # avatar_url: 导游头像
  # video_url: 介绍视频
  
  # Associations
  has_many :deep_travel_products, dependent: :destroy
  has_many :availabilities, class_name: 'DeepTravelAvailability', dependent: :destroy
  has_many :deep_travel_reviews, dependent: :destroy
  
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
end
