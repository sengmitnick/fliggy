class DeepTravelBooking < ApplicationRecord
  include DataVersionable
  belongs_to :user
  belongs_to :deep_travel_guide
  belongs_to :deep_travel_product
  has_many :booking_travelers, dependent: :destroy

  validates :travel_date, presence: true
  validates :adult_count, numericality: { greater_than_or_equal_to: 0 }
  validates :child_count, numericality: { greater_than_or_equal_to: 0 }
  validates :contact_name, presence: true
  validates :contact_phone, presence: true, format: { with: /\A1[3-9]\d{9}\z/, message: "手机号码格式不正确" }
  validates :total_price, numericality: { greater_than: 0 }
  
  accepts_nested_attributes_for :booking_travelers, allow_destroy: true
  
  # 订单状态: pending(待支付), paid(已支付), confirmed(已确认), completed(已完成), cancelled(已取消)
  enum :status, {
    pending: 'pending',
    paid: 'paid', 
    confirmed: 'confirmed',
    completed: 'completed',
    cancelled: 'cancelled'
  }, prefix: true
  
  # 生成订单编号
  before_create :generate_order_number
  
  def total_travelers
    adult_count + child_count
  end
  
  private
  
  def generate_order_number
    self.order_number = "DT#{Time.now.strftime('%Y%m%d%H%M%S')}#{rand(1000..9999)}"
  end
end
