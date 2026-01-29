class Ticket < ApplicationRecord
  include DataVersionable
  belongs_to :attraction
  belongs_to :supplier, optional: true
  has_many :ticket_suppliers, dependent: :destroy
  has_many :suppliers, through: :ticket_suppliers
  has_many :ticket_orders, dependent: :destroy
  has_one_attached :image
  
  validates :name, presence: true
  validates :current_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :ticket_type, inclusion: { in: %w[adult child] }
  
  scope :available, -> { where("stock > 0 OR stock = -1") }
  scope :by_type, ->(type) { where(ticket_type: type) if type.present? }
  
  # 是否有库存
  def in_stock?
    stock == -1 || stock > 0
  end
  
  # 折扣百分比
  def discount_percentage
    return 0 if original_price.blank? || original_price.zero?
    ((original_price - current_price) / original_price * 100).round
  end
end
