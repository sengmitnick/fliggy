class CabinType < ApplicationRecord
  include DataVersionable
  
  belongs_to :cruise_ship
  has_many :cruise_products, dependent: :destroy
  
  validates :name, :category, presence: true
  validates :area, numericality: { greater_than: 0 }, allow_nil: true
  validates :max_occupancy, numericality: { greater_than: 0 }
  
  # 舱房类型
  CATEGORIES = {
    'balcony' => '阳台房',
    'ocean_view' => '海景房',
    'interior' => '内舱房',
    'suite' => '套房'
  }.freeze
  
  def category_name
    CATEGORIES[category] || category
  end
  
  # 获取图片列表
  def image_list
    image_urls.is_a?(Array) ? image_urls : []
  end
  
  # 获取特性标签
  def feature_badges
    badges = []
    badges << "#{area}m²" if area.present? && area > 0
    badges << '有阳台' if has_balcony
    badges << '有窗户' if has_window
    badges << "最多#{max_occupancy}人" if max_occupancy
    badges
  end
end
