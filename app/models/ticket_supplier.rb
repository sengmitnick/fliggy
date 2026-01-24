class TicketSupplier < ApplicationRecord
  include DataVersionable
  
  belongs_to :ticket
  belongs_to :supplier
  
  validates :current_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  scope :available, -> { where("stock > 0 OR stock = -1") }
  scope :by_supplier, ->(supplier_id) { where(supplier_id: supplier_id) if supplier_id.present? }
  
  # 折扣百分比
  def discount_percentage
    return 0 if original_price.blank? || original_price.zero?
    ((original_price - current_price) / original_price * 100).round
  end
end
