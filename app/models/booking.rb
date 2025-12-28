class Booking < ApplicationRecord
  belongs_to :user
  belongs_to :flight
  belongs_to :return_flight, class_name: 'Flight', optional: true
  belongs_to :return_offer, class_name: 'FlightOffer', optional: true

  validates :passenger_name, :passenger_id_number, :contact_phone, :total_price, presence: true
  validates :contact_phone, format: { with: /\A1[3-9]\d{9}\z/, message: "手机号码格式不正确" }
  validates :total_price, numericality: { greater_than: 0 }
  validates :accept_terms, acceptance: true
  validates :insurance_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :return_flight_id, presence: true, if: -> { trip_type == 'round_trip' }
  validates :return_date, presence: true, if: -> { trip_type == 'round_trip' }

  # 订单状态
  enum :status, {
    pending: 'pending',      # 待支付
    paid: 'paid',           # 已支付
    cancelled: 'cancelled',  # 已取消
    completed: 'completed'   # 已完成
  }

  # 行程类型
  enum :trip_type, {
    one_way: 'one_way',       # 单程
    round_trip: 'round_trip', # 往返
    multi_city: 'multi_city'  # 多程
  }, default: 'one_way'

  # 判断是否为往返票
  def round_trip?
    trip_type == 'round_trip'
  end
end
