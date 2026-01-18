class FlightOffer < ApplicationRecord
  include DataVersionable
  belongs_to :flight

  # Serialize arrays for services, tags, and discount_items
  serialize :services, type: Array, coder: JSON
  serialize :tags, type: Array, coder: JSON
  serialize :discount_items, type: Array, coder: JSON

  validates :provider_name, :price, presence: true
  validates :price, numericality: { greater_than: 0 }

  scope :ordered, -> { order(:display_order, :price) }
  scope :featured, -> { where(is_featured: true) }

  # Offer types
  OFFER_TYPES = {
    'standard' => '标准',
    'featured' => '超值精选',
    'cashback' => '返现礼遇',
    'family' => '家庭好价',
    'meal_package' => '旅行套餐'
  }.freeze

  # Calculate final price after cashback
  def final_price
    price - cashback_amount
  end

  # Get discount percentage
  def discount_percentage
    return 0 unless original_price && original_price > 0
    ((original_price - price) / original_price * 100).round(1)
  end

  # Check if offer has discount
  def has_discount?
    original_price && original_price > price
  end

  # Format discount items for display
  def formatted_discount_items
    return [] unless discount_items.is_a?(Array)
    discount_items
  end

  # Format services for display
  def formatted_services
    return [] unless services.is_a?(Array)
    services
  end

  # Format tags for display
  def formatted_tags
    return [] unless tags.is_a?(Array)
    tags
  end

  # Get offer type label
  def offer_type_label
    OFFER_TYPES[offer_type] || '标准'
  end
end
