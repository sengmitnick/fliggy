class BusTicketOrder < ApplicationRecord
  belongs_to :user
  belongs_to :bus_ticket
  
  validates :passenger_name, :passenger_id_number, :contact_phone, :total_price, presence: true
  validates :status, inclusion: { in: %w[pending paid confirmed cancelled refunded] }
  
  # 状态说明:
  # pending - 待支付
  # paid - 已支付
  # confirmed - 已确认/已出票
  # cancelled - 已取消
  # refunded - 已退款
end
