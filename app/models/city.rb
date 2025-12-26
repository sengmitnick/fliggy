class City < ApplicationRecord
  serialize :themes, coder: JSON
  
  validates :name, presence: true, uniqueness: true
  validates :pinyin, presence: true
  validates :region, presence: true
  
  scope :hot_cities, -> { where(is_hot: true) }
  scope :by_region, ->(region) { where(region: region) }
  scope :by_theme, ->(theme) { where("themes LIKE ?", "%#{theme}%") }
end
