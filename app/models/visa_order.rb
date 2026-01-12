class VisaOrder < ApplicationRecord
  extend FriendlyId
  friendly_id :generate_slug, use: :slugged

  belongs_to :user
  belongs_to :visa_product
  has_many :visa_order_travelers, dependent: :destroy

  validates :traveler_count, numericality: { greater_than: 0 }
  validates :total_price, numericality: { greater_than_or_equal_to: 0 }
  validates :unit_price, numericality: { greater_than_or_equal_to: 0 }
  validates :contact_name, presence: true
  validates :contact_phone, presence: true, format: { with: /\A1[3-9]\d{9}\z/, message: "手机号码格式不正确" }
  validates :delivery_address, presence: true

  # 订单状态
  enum :status, {
    pending: 'pending',      # 待支付
    paid: 'paid',           # 已支付
    processing: 'processing', # 处理中
    completed: 'completed',   # 已完成
    cancelled: 'cancelled'   # 已取消
  }, default: 'pending'

  # 支付状态
  enum :payment_status, {
    unpaid: 'unpaid',       # 未支付
    paid: 'paid',           # 已支付
    refunded: 'refunded'    # 已退款
  }, default: 'unpaid'

  private

  def generate_slug
    "visa-#{user_id}-#{Time.current.to_i}"
  end
end
