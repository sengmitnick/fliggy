class ActivityOrder < ApplicationRecord
  include DataVersionable
  belongs_to :user
  belongs_to :attraction_activity
  
  validates :passenger_name, presence: true
  validates :contact_phone, presence: true
  validates :visit_date, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :total_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, inclusion: { in: %w[pending paid confirmed completed cancelled refunded] }
  
  before_validation :generate_order_number, on: :create
  before_validation :calculate_total_price, on: :create
  
  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :recent, -> { order(created_at: :desc) }
  
  private
  
  def generate_order_number
    self.order_number ||= "AO#{Time.current.strftime('%Y%m%d%H%M%S')}#{SecureRandom.hex(4).upcase}"
  end
  
  def calculate_total_price
    self.total_price = attraction_activity.current_price * quantity if attraction_activity && quantity
  end
end
