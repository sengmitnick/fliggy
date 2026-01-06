class TourPackage < ApplicationRecord
  belongs_to :tour_group_product

  validates :name, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :child_price, numericality: { greater_than_or_equal_to: 0 }

  scope :featured, -> { where(is_featured: true) }
  scope :by_display_order, -> { order(display_order: :asc) }
  scope :by_popularity, -> { order(purchase_count: :desc) }

  def format_price
    "¥#{price.to_i}"
  end

  def format_child_price
    return nil if child_price == 0
    "¥#{child_price.to_i}"
  end

  def purchase_percentage
    return 0 if purchase_count == 0
    # 计算购买百分比，基于总购买量
    total = tour_group_product.tour_packages.sum(:purchase_count)
    return 0 if total == 0
    ((purchase_count.to_f / total) * 100).round
  end
end
