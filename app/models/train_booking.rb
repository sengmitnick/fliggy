class TrainBooking < ApplicationRecord
  include DataVersionable
  belongs_to :user
  belongs_to :train

  validates :passenger_name, :passenger_id_number, :contact_phone, :total_price, :seat_type, presence: true
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

  # 座位类型
  enum :seat_type, {
    second_class: 'second_class',      # 二等座
    first_class: 'first_class',        # 一等座
    business_class: 'business_class',  # 商务座
    no_seat: 'no_seat'                 # 无座
  }, suffix: true

  # 获取座位类型中文名
  def seat_type_label
    case seat_type
    when 'second_class'
      '二等座'
    when 'first_class'
      '一等座'
    when 'business_class'
      '商务座'
    when 'no_seat'
      '无座'
    else
      '未知'
    end
  end

  # 获取座位信息（车厢+座位号）
  def seat_info
    return '未分配' if carriage_number.blank? || seat_number.blank?
    "#{carriage_number}车厢 #{seat_number}"
  end

  # 创建预订成功通知
  def create_booking_notification
    return unless user.present?
    
    train_info = "#{train.departure_city}-#{train.arrival_city} #{train.train_number}"
    
    user.notifications.create!(
      category: 'itinerary',
      title: '订单行程消息提醒',
      content: "预定成功，#{train_info}，出发时间：#{train.departure_time.strftime('%m月%d日 %H:%M')}",
      read: false
    )
  end
  
  # 创建出票成功通知
  def create_ticket_issued_notification
    return unless user.present?
    
    train_info = "#{train.departure_city}-#{train.arrival_city} #{train.train_number}"
    
    user.notifications.create!(
      category: 'itinerary',
      title: '火车票出票成功',
      content: "您购买的#{train_info}已出票，#{seat_info}，点击查看详情",
      read: false
    )
  end
end
