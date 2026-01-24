class ActivityOrder < ApplicationRecord
  include DataVersionable
  belongs_to :user
  belongs_to :attraction_activity
  
  # passenger_ids存储为PG jsonb类型，不需要serialize
  
  validates :visit_date, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :total_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, inclusion: { in: %w[pending paid confirmed completed cancelled refunded] }
  validates :insurance_type, inclusion: { in: %w[none basic premium] }
  
  validate :passenger_ids_match_quantity
  
  before_validation :generate_order_number, on: :create
  before_validation :calculate_total_price, on: :create
  
  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :recent, -> { order(created_at: :desc) }
  
  # 获取选中的乘客
  def passengers
    return [] if passenger_ids.blank?
    Passenger.where(id: passenger_ids)
  end
  
  # 保险价格
  def insurance_price
    case insurance_type
    when 'basic' then 9
    when 'premium' then 15
    else 0
    end
  end
  
  private
  
  def generate_order_number
    self.order_number ||= "AO#{Time.current.strftime('%Y%m%d%H%M%S')}#{SecureRandom.hex(4).upcase}"
  end
  
  def calculate_total_price
    if attraction_activity && quantity
      base_price = attraction_activity.current_price * quantity
      insurance_total = insurance_price * quantity
      self.total_price = base_price + insurance_total
    end
  end
  
  def passenger_ids_match_quantity
    return if passenger_ids.blank? # 允许为空，用于passenger_name方式
    if passenger_ids.is_a?(Array) && passenger_ids.size != quantity
      errors.add(:passenger_ids, "选择的出行人数量必须等于购买数量")
    end
  end
end
