class Booking < ApplicationRecord
  include DataVersionable
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
  validates :multi_city_flights, presence: true, if: -> { trip_type == 'multi_city' }

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
  
  # 判断是否为多程票
  def multi_city?
    trip_type == 'multi_city'
  end
  
  # 获取多程航班列表
  def multi_city_flight_objects
    return [] unless multi_city? && multi_city_flights.present?
    
    multi_city_flights.map do |flight_data|
      Flight.find_by(id: flight_data['flight_id'])
    end.compact
  end
  
  # 创建预订成功通知
  def create_booking_notification
    return unless user.present?
    
    flight_info = if multi_city?
      "#{multi_city_flight_objects.first&.departure_city}-#{multi_city_flight_objects.last&.destination_city} 多程"
    elsif round_trip?
      "#{flight.departure_city}-#{flight.destination_city} 往返"
    else
      "#{flight.departure_city}-#{flight.destination_city} #{flight.flight_number}"
    end
    
    user.notifications.create!(
      category: 'itinerary',
      title: '订单行程消息提醒',
      content: "预定成功，请报张润胜办理入住维也纳国际酒店·武汉华中科技大学佳园路地铁站",
      read: false
    )
  end
  
  # 创建出票成功通知
  def create_ticket_issued_notification
    return unless user.present?
    
    flight_info = if multi_city?
      "#{multi_city_flight_objects.first&.departure_city}-#{multi_city_flight_objects.last&.destination_city} 多程"
    elsif round_trip?
      "#{flight.departure_city}-#{return_flight.destination_city}"
    else
      "#{flight.departure_city}-#{flight.destination_city} #{flight.flight_number}"
    end
    
    user.notifications.create!(
      category: 'itinerary',
      title: '机票出票成功',
      content: "您购买的#{flight_info}已出票，点击查看详情",
      read: false
    )
  end
end
