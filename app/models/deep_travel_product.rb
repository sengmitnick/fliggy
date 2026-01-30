class DeepTravelProduct < ApplicationRecord
  include DataVersionable
  # Associations
  belongs_to :deep_travel_guide
  
  # 图片字段: image_urls (JSON 数组)
  serialize :image_urls, coder: JSON
  
  # Validations
  validates :title, presence: true
  validates :location, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :sales_count, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  
  # Scopes
  scope :featured, -> { where(featured: true) }
  scope :by_location, ->(location) { where(location: location) }
  scope :recent, -> { order(created_at: :desc) }
end
