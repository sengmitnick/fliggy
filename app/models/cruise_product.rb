class CruiseProduct < ApplicationRecord
  include DataVersionable
  
  belongs_to :cruise_sailing
  belongs_to :cabin_type
  has_many :cruise_orders, dependent: :destroy
  
  validates :merchant_name, presence: true
  validates :price_per_person, numericality: { greater_than: 0 }
  validates :occupancy_requirement, numericality: { greater_than: 0 }
  validates :stock, :sales_count, numericality: { greater_than_or_equal_to: 0 }
  
  # 产品状态
  enum :status, {
    on_sale: 'on_sale',
    sold_out: 'sold_out',
    off_shelf: 'off_shelf'
  }, suffix: true
  
  # 计算总价（基于人数）
  def total_price_for(quantity)
    price_per_person * quantity
  end
  
  # 检查是否有库存
  def in_stock?
    stock > 0 && on_sale?
  end
  
  # 获取标签样式类
  def badge_class
    case badge
    when '近期热销'
      'bg-red-100 text-red-600'
    when '低价之选'
      'bg-orange-100 text-orange-600'
    else
      'bg-gray-100 text-gray-600'
    end
  end
end
