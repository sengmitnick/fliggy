class Booking < ApplicationRecord
  belongs_to :user
  belongs_to :flight

  validates :passenger_name, :passenger_id_number, :contact_phone, :total_price, presence: true
  validates :contact_phone, format: { with: /\A1[3-9]\d{9}\z/, message: "手机号码格式不正确" }
  validates :total_price, numericality: { greater_than: 0 }
  validates :accept_terms, acceptance: true
  validates :insurance_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # 订单状态
  enum :status, {
    pending: 'pending',      # 待支付
    paid: 'paid',           # 已支付
    cancelled: 'cancelled',  # 已取消
    completed: 'completed'   # 已完成
  }
end
