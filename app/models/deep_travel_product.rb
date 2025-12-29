class DeepTravelProduct < ApplicationRecord
  # Associations
  belongs_to :deep_travel_guide
  
  # ActiveStorage attachments for multiple images
  has_many_attached :images
  
  # Validations
  validates :title, presence: true
  validates :location, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :sales_count, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  
  # Scopes
  scope :featured, -> { where(featured: true) }
  scope :by_location, ->(location) { where(location: location) }
  scope :recent, -> { order(created_at: :desc) }
  
  # Helper methods
  def image_urls
    images.map { |image| Rails.application.routes.url_helpers.rails_blob_url(image) } if images.attached?
  end
end
