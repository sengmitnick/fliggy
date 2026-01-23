class CruiseOrder < ApplicationRecord
  include DataVersionable
  
  belongs_to :user
  belongs_to :cruise_product
  
  validates :quantity, numericality: { greater_than: 0 }
  validates :total_price, numericality: { greater_than: 0 }
  validates :contact_name, :contact_phone, presence: true
  validates :contact_phone, format: { with: /\A1[3-9]\d{9}\z/ }
  validates :accept_terms, acceptance: true
  
  before_validation :generate_order_number, on: :create
  before_validation :calculate_total_price
  
  # 订单状态
  enum :status, {
    pending: 'pending',
    paid: 'paid',
    cancelled: 'cancelled',
    completed: 'completed'
  }, suffix: true
  
  # 获取乘客列表
  def passenger_list
    passenger_info.is_a?(Array) ? passenger_info : []
  end
  
  # 生成订单通知
  def create_order_notification
    return unless user.present?
    
    ship_name = cruise_product.cruise_sailing.cruise_ship.name
    date_range = cruise_product.cruise_sailing.date_range
    
    user.notifications.create!(
      category: 'itinerary',
      title: '游轮订单支付成功',
      content: "您的#{ship_name}订单已支付成功，出发日期：#{date_range}",
      read: false
    )
  end
  
  private
  
  def generate_order_number
    self.order_number ||= "CR#{Time.current.strftime('%Y%m%d%H%M%S')}#{SecureRandom.hex(4).upcase}"
  end
  
  def calculate_total_price
    return unless cruise_product.present? && quantity.present?
    
    base_price = cruise_product.price_per_person * quantity
    insurance = insurance_price || 0
    self.total_price = base_price + insurance
  end
end
