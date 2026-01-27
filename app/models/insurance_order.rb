class InsuranceOrder < ApplicationRecord
  include DataVersionable
  
  # Associations
  belongs_to :user
  belongs_to :insurance_product
  belongs_to :related_booking, polymorphic: true, optional: true
  
  # Validations
  validates :order_number, presence: true, uniqueness: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :days, presence: true, numericality: { greater_than: 0 }
  validates :unit_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :total_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, presence: true, inclusion: { in: %w[pending paid effective expired cancelled] }
  validates :source, presence: true, inclusion: { in: %w[standalone embedded] }
  validate :end_date_after_start_date
  
  # Callbacks
  before_validation :calculate_days, if: -> { start_date.present? && end_date.present? }
  before_validation :calculate_total_price, if: -> { unit_price.present? && quantity.present? }
  before_validation :generate_order_number, unless: :order_number?, on: :create
  before_create :generate_policy_number
  
  # Scopes
  scope :pending, -> { where(status: 'pending') }
  scope :paid, -> { where(status: 'paid') }
  scope :effective, -> { where(status: 'effective') }
  scope :expired, -> { where(status: 'expired') }
  scope :cancelled, -> { where(status: 'cancelled') }
  scope :standalone, -> { where(source: 'standalone') }
  scope :embedded, -> { where(source: 'embedded') }
  scope :recent, -> { order(created_at: :desc) }
  
  # Instance methods
  def pending?
    status == 'pending'
  end
  
  def paid?
    status == 'paid'
  end
  
  def cancelled?
    status == 'cancelled'
  end
  
  def effective?
    status == 'effective' && Date.current.between?(start_date, end_date)
  end
  
  def expired?
    status == 'expired' || (Date.current > end_date && status != 'cancelled')
  end
  
  def can_cancel?
    status == 'pending' || (status == 'paid' && start_date > Date.current)
  end
  
  def status_name
    case status
    when 'pending'
      '待支付'
    when 'paid'
      '已支付'
    when 'effective'
      '保障中'
    when 'expired'
      '已过期'
    when 'cancelled'
      '已取消'
    else
      status
    end
  end
  
  def source_name
    case source
    when 'standalone'
      '单独购买'
    when 'embedded'
      '随订单购买'
    else
      source
    end
  end
  
  private
  
  def calculate_days
    self.days = (end_date - start_date).to_i + 1
  end
  
  def calculate_total_price
    self.total_price = (unit_price * quantity).round(2)
  end
  
  def generate_order_number
    self.order_number = "INS#{Time.current.strftime('%Y%m%d')}#{SecureRandom.hex(6).upcase}"
  end
  
  def generate_policy_number
    self.policy_number = "POL-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(4).upcase}"
  end
  
  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?
    
    if end_date < start_date
      errors.add(:end_date, '必须晚于开始日期')
    end
  end
end
