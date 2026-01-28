class MembershipOrder < ApplicationRecord
  belongs_to :user
  belongs_to :membership_product
  
  # Status constants
  STATUSES = {
    'pending' => '待支付',
    'paid' => '已支付',
    'shipping' => '配送中',
    'completed' => '已完成',
    'cancelled' => '已取消'
  }.freeze
  
  validates :quantity, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: STATUSES.keys }
  validates :order_number, presence: true, uniqueness: true
  validates :contact_name, presence: true
  validates :contact_phone, presence: true
  validates :shipping_address, presence: true
  
  before_validation :generate_order_number, on: :create
  before_validation :calculate_totals, on: :create
  
  scope :recent, -> { order(created_at: :desc) }
  scope :by_status, ->(status) { where(status: status) if status.present? }
  
  def status_name
    STATUSES[status] || status
  end
  
  def can_cancel?
    status == 'pending'
  end
  
  def can_pay?
    status == 'pending'
  end
  
  def total_display
    parts = []
    parts << "#{total_mileage}里程" if total_mileage > 0
    parts << "#{total_cash}元" if total_cash > 0
    parts.join(' + ')
  end
  
  private
  
  def generate_order_number
    self.order_number ||= "MS#{Time.current.strftime('%Y%m%d%H%M%S')}#{SecureRandom.hex(4).upcase}"
  end
  
  def calculate_totals
    self.price_cash = membership_product.price_cash
    self.price_mileage = membership_product.price_mileage
    self.total_cash = price_cash * quantity
    self.total_mileage = price_mileage * quantity
  end
end
