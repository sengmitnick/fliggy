class HotelBooking < ApplicationRecord
  belongs_to :hotel
  belongs_to :user, optional: true
  belongs_to :hotel_room

  validates :check_in_date, :check_out_date, presence: { message: '不能为空' }
  validates :guest_name, presence: { message: '请填写入住人姓名' }
  validates :guest_phone, presence: { message: '请填写联系手机' }
  validates :total_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :rooms_count, :adults_count, numericality: { greater_than: 0 }
  validates :children_count, numericality: { greater_than_or_equal_to: 0 }
  validates :payment_method, inclusion: { in: ['花呗', '花呗分期'] }
  validates :status, inclusion: { in: %w[pending confirmed cancelled completed paid] }
  validates :insurance_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  
  validate :check_out_after_check_in
  validate :lock_not_expired, if: -> { status == 'pending' && locked_until.present? }

  # 计算总价（包含保险）
  def total_price_with_insurance
    (total_price || 0) + (insurance_price || 0)
  end

  # 计算入住天数
  def nights
    return 0 if check_in_date.nil? || check_out_date.nil?
    (check_out_date - check_in_date).to_i
  end

  # 计算总价
  def calculate_total_price
    return 0 if hotel_room.nil? || nights <= 0
    base_price = hotel_room.price * nights * rooms_count
    self.original_price = base_price
    self.total_price = base_price - (discount_amount || 0)
  end

  private

  def check_out_after_check_in
    return if check_in_date.blank? || check_out_date.blank?
    
    if check_out_date <= check_in_date
      errors.add(:check_out_date, '必须在入住日期之后')
    end
  end
  
  def lock_not_expired
    if locked_until.present? && locked_until < Time.current
      errors.add(:base, '订单已过期，请重新预订')
    end
  end
end
