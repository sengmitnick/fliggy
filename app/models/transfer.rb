class Transfer < ApplicationRecord
  belongs_to :user
  belongs_to :transfer_package, optional: true

  validates :transfer_type, presence: true, inclusion: { in: %w[airport_pickup train_pickup] }
  validates :service_type, presence: true, inclusion: { in: %w[to_airport from_airport to_station from_station] }
  validates :location_from, :location_to, :pickup_datetime, presence: true
  validates :passenger_name, :passenger_phone, presence: true
  validates :passenger_phone, format: { with: /\A1[3-9]\d{9}\z/, message: "手机号码格式不正确" }
  validates :total_price, numericality: { greater_than_or_equal_to: 0 }
  validates :driver_status, inclusion: { in: %w[pending accepted driving arrived completed cancelled] }
  validates :status, inclusion: { in: %w[pending paid cancelled completed refunded] }

  # 订单状态枚举
  enum :status, {
    pending: 'pending',      # 待支付
    paid: 'paid',           # 已支付
    cancelled: 'cancelled',  # 已取消
    completed: 'completed',  # 已完成
    refunded: 'refunded'    # 已退款
  }, validate: false

  # 司机状态枚举
  enum :driver_status, {
    pending: 'pending',      # 待接单
    accepted: 'accepted',    # 已接单
    driving: 'driving',      # 前往中
    arrived: 'arrived',      # 已到达
    completed: 'completed',  # 已完成
    cancelled: 'cancelled'   # 已取消
  }, validate: false, prefix: :driver

  scope :recent, -> { order(created_at: :desc) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :by_status, ->(status) { where(status: status) }
  scope :airport_transfers, -> { where(transfer_type: 'airport_pickup') }
  scope :train_transfers, -> { where(transfer_type: 'train_pickup') }

  # 判断是否为机场接送
  def airport_transfer?
    transfer_type == 'airport_pickup'
  end

  # 判断是否为火车站接送
  def train_transfer?
    transfer_type == 'train_pickup'
  end

  # 判断是否为接（到机场/车站接我）
  def pickup_service?
    service_type.in?(%w[from_airport from_station])
  end

  # 判断是否为送（送我到机场/车站）
  def dropoff_service?
    service_type.in?(%w[to_airport to_station])
  end

  # 获取服务名称
  def service_name
    if airport_transfer?
      pickup_service? ? '机场接机' : '机场送机'
    else
      pickup_service? ? '火车站接站' : '火车站送站'
    end
  end

  # 格式化用车时间
  def pickup_datetime_formatted
    pickup_datetime&.strftime('%m月%d日 %H:%M')
  end

  # 格式化用车日期
  def pickup_date_formatted
    pickup_datetime&.strftime('%Y年%m月%d日')
  end

  # 格式化用车时间（仅时间）
  def pickup_time_formatted
    pickup_datetime&.strftime('%H:%M')
  end

  # 获取司机状态文本
  def driver_status_text
    case driver_status
    when 'pending' then '司机未接单'
    when 'accepted' then '司机已接单'
    when 'driving' then '司机前往中'
    when 'arrived' then '司机已到达'
    when 'completed' then '行程已完成'
    when 'cancelled' then '订单已取消'
    else '未知状态'
    end
  end

  # 获取订单状态文本
  def status_text
    case status
    when 'pending' then '待支付'
    when 'paid' then '已支付'
    when 'cancelled' then '已取消'
    when 'completed' then '已完成'
    when 'refunded' then '已退款'
    else '未知状态'
    end
  end

  # 模拟司机接单（支付成功后几分钟自动接单）
  def simulate_driver_acceptance
    return unless paid? && driver_pending?
    
    # 延迟2-5分钟后接单
    delay = rand(2..5).minutes
    # 这里可以使用后台任务，暂时先直接更新
    update(driver_status: 'accepted')
  end

  # 计算实付金额
  def actual_price
    total_price - discount_amount
  end

  # 创建订单通知
  def create_transfer_notification
    return unless user.present?
    
    user.notifications.create!(
      category: 'itinerary',
      title: '接送订单确认',
      content: "订单确认信息将发送到您预留的乘车人手机号上，请注意查收",
      read: false
    )
  end
end
