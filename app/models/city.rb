class City < ApplicationRecord
  include DataVersionable
  serialize :themes, coder: JSON
  
  validates :name, presence: true, uniqueness: true
  validates :pinyin, presence: true
  validates :region, presence: true
  
  scope :hot_cities, -> { where(is_hot: true) }
  scope :by_region, ->(region) { where(region: region) }
  scope :by_theme, ->(theme) { where("themes LIKE ?", "%#{theme}%") }
  
  # Clear cache when city data changes
  after_save :clear_city_cache
  after_destroy :clear_city_cache
  
  private
  
  def clear_city_cache
    Rails.cache.delete('cities/hot_cities')
    Rails.cache.delete('cities/all_cities')
  end
end
