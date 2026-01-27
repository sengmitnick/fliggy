class InsuranceProduct < ApplicationRecord
  include DataVersionable
  
  # Validations
  validates :name, presence: true
  validates :company, presence: true
  validates :product_type, presence: true, inclusion: { in: %w[domestic international transport] }
  validates :code, presence: true, uniqueness: true
  validates :price_per_day, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  # Associations
  has_many :insurance_orders, dependent: :restrict_with_error
  has_many :insurance_product_cities, dependent: :destroy
  has_many :cities, through: :insurance_product_cities
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :featured, -> { where(featured: true) }
  scope :official_select, -> { where(official_select: true) }
  scope :domestic, -> { where(product_type: 'domestic') }
  scope :international, -> { where(product_type: 'international') }
  scope :transport, -> { where(product_type: 'transport') }
  scope :embeddable, -> { where(available_for_embedding: true) }
  scope :by_company, ->(company) { where(company: company) }
  scope :with_scenes, ->(scenes) { where("scenes && ARRAY[?]::varchar[]", scenes) }
  scope :sorted, -> { order(featured: :desc, sort_order: :desc, created_at: :desc) }
  scope :available_in_city, ->(city_id) {
    joins(:insurance_product_cities)
      .where(insurance_product_cities: { city_id: city_id, available: true })
      .distinct
  }
  
  # Calculate price for given days (optionally for specific city)
  def calculate_price(days, city_id: nil)
    return 0 if days < min_days
    return nil if days > max_days
    
    price = if city_id
      city_config = insurance_product_cities.find_by(city_id: city_id)
      city_config&.effective_price_per_day || price_per_day
    else
      price_per_day
    end
    
    (price * days).round(2)
  end
  
  # Get price per day for specific city
  def price_for_city(city_id)
    city_config = insurance_product_cities.find_by(city_id: city_id)
    city_config&.effective_price_per_day || price_per_day
  end
  
  # Check if available in city
  def available_in_city?(city_id)
    return true if insurance_product_cities.empty? # If no city restrictions, available everywhere
    insurance_product_cities.available.exists?(city_id: city_id)
  end
  
  # Get coverage amount
  def coverage_accident
    coverage_details['accident']&.to_i || 0
  end
  
  def coverage_medical
    coverage_details['medical']&.to_i || 0
  end
  
  def coverage_trip_cancellation
    coverage_details['trip_cancellation']&.to_i || 0
  end
  
  # Display helpers
  def product_type_name
    case product_type
    when 'domestic'
      '境内旅行'
    when 'international'
      '境外/港澳台旅行'
    when 'transport'
      '交通意外'
    else
      product_type
    end
  end
  
  def price_range_display(city_id: nil)
    price = city_id ? price_for_city(city_id) : price_per_day
    return "¥#{price}/天" if min_days == 1 && max_days == 1
    "¥#{price}/天起"
  end
end
