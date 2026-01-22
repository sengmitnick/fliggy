class InsuranceProductCity < ApplicationRecord
  # Associations
  belongs_to :insurance_product
  belongs_to :city
  
  # Validations
  validates :insurance_product_id, presence: true
  validates :city_id, presence: true
  validates :insurance_product_id, uniqueness: { scope: :city_id, message: "已经关联了该城市" }
  validates :price_per_day, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  
  # Scopes
  scope :available, -> { where(available: true) }
  scope :for_product, ->(product_id) { where(insurance_product_id: product_id) }
  scope :for_city, ->(city_id) { where(city_id: city_id) }
  
  # Get effective price (fallback to product default price if not set)
  def effective_price_per_day
    price_per_day.presence || insurance_product.price_per_day
  end
  
  # Calculate price for given days
  def calculate_price(days)
    return 0 if days < insurance_product.min_days
    return nil if days > insurance_product.max_days
    (effective_price_per_day * days).round(2)
  end
end
