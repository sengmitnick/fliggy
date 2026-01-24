class BusTicketOrder < ApplicationRecord
  include DataVersionable
  belongs_to :user
  belongs_to :bus_ticket
  has_many :passengers, class_name: 'BusTicketPassenger', dependent: :destroy
  
  validates :total_price, :passenger_count, presence: true
  validates :status, inclusion: { in: %w[pending paid confirmed cancelled refunded] }
  validates :passenger_count, numericality: { greater_than: 0 }
  
  # 状态说明:
  # pending - 待支付
  # paid - 已支付
  # confirmed - 已确认/已出票
  # cancelled - 已取消
  # refunded - 已退款
end
