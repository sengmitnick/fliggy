class CharterBooking < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :charter_route
  belongs_to :vehicle_type

  # Validations
  validates :user_id, presence: true
  validates :charter_route_id, presence: true
  validates :vehicle_type_id, presence: true
  validates :departure_date, presence: true
  validates :departure_time, presence: true
  validates :duration_hours, presence: true, inclusion: { in: [6, 8] }
  validates :booking_mode, presence: true, inclusion: { in: %w[by_route by_time] }
  validates :contact_name, presence: true
  validates :contact_phone, presence: true, format: { with: /\A1[3-9]\d{9}\z/, message: "格式不正确" }
  validates :passengers_count, presence: true, numericality: { greater_than: 0 }
  validates :total_price, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: %w[pending paid completed cancelled refunded] }
  validates :order_number, uniqueness: true, allow_nil: true
  validate :departure_date_cannot_be_in_the_past
  validate :passengers_cannot_exceed_vehicle_seats

  # Callbacks
  before_validation :generate_order_number, on: :create
  before_validation :calculate_total_price, if: -> { total_price.blank? }

  # Scopes
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :by_status, ->(status) { where(status: status) }
  scope :pending, -> { where(status: 'pending') }
  scope :paid, -> { where(status: 'paid') }
  scope :completed, -> { where(status: 'completed') }
  scope :cancelled, -> { where(status: 'cancelled') }
  scope :recent, -> { order(created_at: :desc) }
  scope :upcoming, -> { where('departure_date >= ?', Date.today).order(:departure_date) }

  # State machine methods
  def pay!
    update!(status: 'paid', paid_at: Time.current)
  end

  def complete!
    update!(status: 'completed')
  end

  def cancel!
    update!(status: 'cancelled')
  end

  def paid?
    status == 'paid' || status == 'completed'
  end

  def can_cancel?
    ['pending', 'paid'].include?(status) && departure_date > Date.today
  end

  # Display methods
  def status_text
    case status
    when 'pending' then '待支付'
    when 'paid' then '已支付'
    when 'completed' then '已完成'
    when 'cancelled' then '已取消'
    when 'refunded' then '已退款'
    else '未知状态'
    end
  end

  def departure_datetime
    return nil if departure_date.blank? || departure_time.blank?
    "#{departure_date.strftime('%Y年%m月%d日')} #{departure_time}"
  end

  private

  def generate_order_number
    self.order_number = "CT#{Time.current.strftime('%Y%m%d%H%M%S')}#{SecureRandom.hex(4).upcase}"
  end

  def calculate_total_price
    return unless vehicle_type && charter_route
    base_price = vehicle_type.price_for_duration(duration_hours)
    # Simple holiday markup (can be enhanced later)
    holiday_markup = departure_date&.saturday? || departure_date&.sunday? ? 1.2 : 1.0
    self.total_price = (base_price * holiday_markup).round(2)
  end

  def departure_date_cannot_be_in_the_past
    return if departure_date.blank?
    errors.add(:departure_date, "不能早于今天") if departure_date < Date.today
  end

  def passengers_cannot_exceed_vehicle_seats
    return unless vehicle_type && passengers_count
    if passengers_count > vehicle_type.seats
      errors.add(:passengers_count, "不能超过车辆座位数（#{vehicle_type.seats}座）")
    end
  end
end
