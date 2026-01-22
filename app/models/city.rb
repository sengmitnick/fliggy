class City < ApplicationRecord
  include DataVersionable
  serialize :themes, coder: JSON
  
  # Associations
  has_many :insurance_product_cities, dependent: :destroy
  has_many :insurance_products, through: :insurance_product_cities
  
  validates :name, presence: true, uniqueness: true
  validates :pinyin, presence: true
  validates :region, presence: true
  
  scope :hot_cities, -> { where(is_hot: true) }
  scope :by_region, ->(region) { where(region: region) }
  scope :by_theme, ->(theme) { where("themes LIKE ?", "%#{theme}%") }
  scope :with_insurance_products, -> { joins(:insurance_product_cities).where(insurance_product_cities: { available: true }).distinct }
  
  # Get available insurance products for this city
  def available_insurance_products
    insurance_products.joins(:insurance_product_cities)
      .where(insurance_product_cities: { city_id: id, available: true })
      .where(insurance_products: { active: true })
  end
  
  # Clear cache when city data changes
  after_save :clear_city_cache
  after_destroy :clear_city_cache
  
  private
  
  def clear_city_cache
    Rails.cache.delete('cities/hot_cities')
    Rails.cache.delete('cities/all_cities')
  end
end
