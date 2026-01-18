class PackageOption < ApplicationRecord
  include DataVersionable
  belongs_to :hotel_package
  
  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :night_count, presence: true, numericality: { greater_than: 0 }
  
  scope :active, -> { where(is_active: true) }
  scope :ordered, -> { order(display_order: :asc, price: :asc) }
  
  # 计算折扣
  def discount_rate
    return 0 if original_price.blank? || original_price.zero?
    ((original_price - price) / original_price * 100).round(1)
  end
  
  # 是否有折扣
  def has_discount?
    original_price.present? && original_price > price
  end
end
