class CruiseSailing < ApplicationRecord
  include DataVersionable
  
  belongs_to :cruise_ship
  belongs_to :cruise_route
  has_many :cruise_products, dependent: :destroy
  
  validates :departure_date, :return_date, :departure_port, :arrival_port, presence: true
  validates :duration_days, :duration_nights, numericality: { greater_than: 0 }
  
  # 订单状态
  enum :status, {
    on_sale: 'on_sale',
    sold_out: 'sold_out',
    cancelled: 'cancelled'
  }, suffix: true
  
  # 获取行程列表
  def itinerary_list
    itinerary.is_a?(Array) ? itinerary : []
  end
  
  # 格式化日期范围
  def date_range
    "#{departure_date.strftime('%m月%d日')} - #{return_date.strftime('%m月%d日')}"
  end
  
  # 获取最低价格
  def min_price
    cruise_products.where(status: 'on_sale').minimum(:price_per_person) || 0
  end
end
